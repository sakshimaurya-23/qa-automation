#!/usr/bin/env python3
"""OMS Business Logic Engine for Test Case Generation."""
import re, json, logging
from pathlib import Path
from typing import Any, Dict, List, Optional

# ---------------------------------------------------------------------------
# Module-level logger
# ---------------------------------------------------------------------------
logger = logging.getLogger("oms_business_logic")
logger.setLevel(logging.DEBUG)
if not logger.handlers:
    _ch = logging.StreamHandler()
    _ch.setLevel(logging.DEBUG)
    _formatter = logging.Formatter("[OMS_LOGIC] %(levelname)-7s | %(message)s")
    _ch.setFormatter(_formatter)
    logger.addHandler(_ch)

# Issue 6 fix: Explicit action-to-query mapping
# Maps the folder name (action API) to the ValidateData API Name (query API)
VALIDATE_API_MAP = {
    "createOrder":              "getOrderList",
    "scheduleOrder":            "getOrderList",
    "releaseOrder":             "getOrderReleaseList",
    "createShipment":           "getShipmentList",
    "changeOrderStatus":        "getOrderList",
    "confirmShipment":          "getShipmentList",
    "orderAcknowledgement":     "getOrderList",
    "shipDepart":               "getShipmentList",
    "CT069ForAutomationService":  "getOrderList",
    "updateOrderFromRouting":   "getOrderList",
    "orderEnquiry":             "getOrderDetails",
    "manageItem":               "getItemList",
    "manageCustomer":           "getCustomerList",
    "adjustInventory":          "getInventorySupply",
    "getDeliveryOptions":       "getDeliveryOptions",
    "getATPForNearestStores":   "getATPForNearestStores",
    "getSurroundingNodeList":   "getSurroundingNodeList",
    "getOrderReleaseList":      "getOrderReleaseList",
}


class BaselineAuditor:
    """
    Issue 4 fix: Baseline integrity auditor.
    Validates that every baseline_data/<API>/ folder has consistent
    ValidateData and expectedResult files before any test case is built.
    """

    @staticmethod
    def get_api_name_from_xml(file_path: Path) -> str:
        """Extract the API Name attribute from a MultiApi XML file."""
        try:
            import xml.etree.ElementTree as ET
            tree = ET.parse(file_path)
            root = tree.getroot()
            api_elem = root.find('.//API')
            if api_elem is not None:
                return api_elem.get('Name', '') or api_elem.get('FlowName', '')
            return ''
        except Exception:
            return ''

    @staticmethod
    def _normalize_root_tag(tag: str) -> str:
        """Normalize equivalent root element tags for comparison.
        Treats ShipmentList and Shipments as equivalent."""
        if tag in ("ShipmentList", "Shipments"):
            return "ShipmentList"
        return tag

    @staticmethod
    def get_root_element_from_template(file_path: Path) -> str:
        """Extract the root child element name from <Template> or <Output> section."""
        try:
            import xml.etree.ElementTree as ET
            tree = ET.parse(file_path)
            root = tree.getroot()
            api_elem = root.find('.//API')
            if api_elem is None:
                return ''
            # Try Template first (ValidateData files), then Output (expectedResult files)
            section = api_elem.find('Template')
            if section is None:
                section = api_elem.find('Output')
            if section is not None and len(section) > 0:
                return BaselineAuditor._normalize_root_tag(section[0].tag)
            return ''
        except Exception:
            return ''

    @staticmethod
    def audit_baseline(baseline_path: Path) -> List[Dict[str, Any]]:
        """
        Audit all folders in baseline_data/ for consistency.
        Returns a list of result dicts, one per folder.
        """
        if not baseline_path.exists():
            return [{"status": "ERROR", "message": f"baseline_data/ not found at {baseline_path}"}]

        results = []
        for folder in sorted(baseline_path.iterdir()):
            if not folder.is_dir():
                continue

            folder_name = folder.name
            validate_file = None
            expected_file = None

            # Find the ValidateData and expectedResult files
            for f in folder.iterdir():
                if f.is_file():
                    if 'validatedata' in f.name.lower():
                        validate_file = f
                    elif f.name.lower().startswith('expectedresult'):
                        expected_file = f

            if validate_file is None or expected_file is None:
                results.append({
                    "folder": folder_name,
                    "status": "SKIP",
                    "message": f"Missing ValidateData or expectedResult file in {folder_name}/"
                })
                continue

            # Get API Names
            validate_api = BaselineAuditor.get_api_name_from_xml(validate_file)
            expected_api = BaselineAuditor.get_api_name_from_xml(expected_file)

            # Get root elements
            validate_root = BaselineAuditor.get_root_element_from_template(validate_file)
            expected_root = BaselineAuditor.get_root_element_from_template(expected_file)

            # Check against VALIDATE_API_MAP
            expected_validate_api = VALIDATE_API_MAP.get(folder_name, '')

            issues = []
            if validate_api and expected_api and validate_api != expected_api:
                issues.append(
                    f"API Name mismatch: ValidateData says '{validate_api}', "
                    f"expectedResult says '{expected_api}'"
                )
            if validate_root and expected_root and validate_root != expected_root:
                issues.append(
                    f"Root element mismatch: ValidateData Template has <{validate_root}>, "
                    f"expectedResult Output has <{expected_root}>"
                )
            if expected_validate_api and validate_api and validate_api != expected_validate_api:
                issues.append(
                    f"Unexpected ValidateData API: folder '{folder_name}' maps to "
                    f"'{expected_validate_api}' but ValidateData says '{validate_api}'"
                )

            if issues:
                results.append({
                    "folder": folder_name,
                    "status": "INCONSISTENT",
                    "validate_api": validate_api,
                    "expected_api": expected_api,
                    "validate_root": validate_root,
                    "expected_root": expected_root,
                    "issues": issues
                })
            else:
                results.append({
                    "folder": folder_name,
                    "status": "CONSISTENT",
                    "validate_api": validate_api,
                    "expected_api": expected_api,
                    "validate_root": validate_root,
                    "expected_root": expected_root
                })

        return results

    @staticmethod
    def print_audit_report(results: List[Dict[str, Any]]) -> str:
        """Format audit results into a human-readable report string."""
        lines = []
        lines.append("=" * 60)
        lines.append("BASELINE INTEGRITY AUDIT REPORT")
        lines.append("=" * 60)

        consistent = 0
        inconsistent = 0
        skipped = 0

        for r in results:
            if r["status"] == "CONSISTENT":
                consistent += 1
                lines.append(f"  ✅ {r['folder']}/ — consistent")
                lines.append(f"     ValidateData API: {r['validate_api']}, Expected API: {r['expected_api']}")
            elif r["status"] == "INCONSISTENT":
                inconsistent += 1
                lines.append(f"  ❌ {r['folder']}/ — INCONSISTENT")
                for issue in r.get("issues", []):
                    lines.append(f"     • {issue}")
            elif r["status"] == "SKIP":
                skipped += 1
                lines.append(f"  ⚠️  {r['folder']}/ — {r['message']}")
            elif r["status"] == "ERROR":
                lines.append(f"  🔴 {r['message']}")

        lines.append("-" * 60)
        lines.append(f"Summary: {consistent} consistent, {inconsistent} inconsistent, {skipped} skipped")
        lines.append("=" * 60)

        return "\n".join(lines)


class OMSConceptExtractor:
    STATUS_CODES = {"1300.01":"INCLUDED_IN_SHIPMENT","1500":"Scheduled","2060":"APTO","3200":"Released","3200.05":"READY_TO_ROUTE","3200.10":"SENT_FOR_ROUTE_TO","3200.20":"SENT_FOR_ROUTE_SO"}
    PATTERNS = {
        "document_type": [r"DocumentType\s*=\s*(CT_0006|0001|CT_0001)", r"\b(Transfer\s+Order)\b", r"\b(Sales\s+Order)\b"],
        "delivery_method": [r"DeliveryMethod\s*=\s*(SHP|PICK|DELIVER)", r"\b(DeliveryMethod=SHP)\b"],
        "release_status": [r"ReleaseStatus\s*=\s*(confirmed|unconfirmed)"],
        "base_drop_status": [r"BaseDropStatus\s*=\s*(\d+(?:\.\d+)?)", r"status\s+is\s+(\d+(?:\.\d+)?)"],
        "extn_mentions": {
            "ExtnWaveId": r"(?:WaveID|WaveId|ExtnWaveId)",
            "ExtnTruckCapacity": r"(?:TruckCapacity|ExtnTruckCapacity)",
            "ExtnRequestedDeliveryDate": r"(?:ReqDeliveryDate|RequestedDeliveryDate|ExtnDeliveryDate)",
            "ExtnReservationStartTime": r"(?:ReservationStartTime|ExtnReservationStartTime)",
            "ExtnReservationEndTime": r"(?:ReservationEndTime|ExtnReservationEndTime)",
            "ExtnDeliveryWindowStartTime": r"(?:DeliveryWindowStartTime|ExtnDeliveryWindowStartTime)",
            "ExtnDeliveryWindowEndTime": r"(?:DeliveryWindowEndTime|ExtnDeliveryWindowEndTime)",
            "ExtnServiceArea": r"(?:ServiceArea|ExtnServiceArea)",
            "ExtnDelServiceType": r"(?:DelServiceType|ExtnDelServiceType|DeliveryType)",
            "ExtnServiceCarrier": r"(?:ServiceCarrier|ExtnServiceCarrier)",
            "ExtnCustomerDesiredDateConfirmation": r"(?:CustomerDesiredDateConfirmation|ExtnCustomerDesiredDateConfirmation)",
        },
        "ship_node": [r"\bShipNode\b"],
        "scac": [r"\bSCAC\b"],
        "carrier_service_code": [r"CarrierServiceCode"],
        "receiving_node": [r"ReceivingNode"],
        "order_line_key": [r"\bOrderLineKey\b"],
        "order_header_key": [r"\bOrderHeaderKey\b"],
        "order_release_key": [r"\bOrderReleaseKey\b"],
    }

    def extract_all(self, text: str) -> Dict[str, Any]:
        if not text:
            return {}
        concepts: Dict[str, Any] = {}
        for pat in self.PATTERNS["document_type"]:
            m = re.search(pat, text, re.IGNORECASE)
            if m:
                concepts["document_type"] = self._normalize_doc_type(m.group(1).strip())
                break
        for pat in self.PATTERNS["delivery_method"]:
            m = re.search(pat, text, re.IGNORECASE)
            if m:
                concepts["delivery_method"] = m.group(1).upper()
                break
        for pat in self.PATTERNS["release_status"]:
            m = re.search(pat, text, re.IGNORECASE)
            if m:
                concepts["release_status"] = m.group(1).upper()
                break
        for pat in self.PATTERNS["base_drop_status"]:
            m = re.search(pat, text, re.IGNORECASE)
            if m:
                concepts["base_drop_status"] = m.group(1)
                break
        for attr, pat in self.PATTERNS["extn_mentions"].items():
            if re.search(pat, text, re.IGNORECASE):
                concepts[attr] = True
        status_codes = [code for code in self.STATUS_CODES if code in text]
        if status_codes:
            concepts["status_codes"] = status_codes
        return concepts

    def extract_from_test_case(self, tc: Dict[str, str]) -> Dict[str, Any]:
        combined = " ".join(tc.get(k, "") for k in ("description", "preconditions", "test_steps", "expected_results"))
        return self.extract_all(combined)

    def apply_fallback_inference(self, concepts: Dict, primary_api: str, title: str) -> Dict:
        """
        Apply fallback inference when CSV content is not rich enough for
        OMSConceptExtractor to extract concepts. Uses Primary_API and title
        keywords to infer DocumentType, DeliveryMethod, and BaseDropStatus.
        Only sets values that are NOT already present in concepts dict.
        """
        title_lower = title.lower() if title else ""

        if "document_type" not in concepts:
            if "transfer" in title_lower:
                concepts["document_type"] = "CT_0006"
            elif "sales" in title_lower:
                concepts["document_type"] = "0001"

        if "delivery_method" not in concepts:
            if "pickup" in title_lower or "pick" in title_lower or "will call" in title_lower:
                concepts["delivery_method"] = "PICK"
            elif "deliver" in title_lower or "delivery" in title_lower or "home delivery" in title_lower:
                concepts["delivery_method"] = "DELIVER"

        if primary_api == "changeOrderStatus" and "base_drop_status" not in concepts:
            concepts["base_drop_status"] = "3200.05"

        if primary_api == "CT069ForAutomationService" and "release_status" not in concepts:
            if "unconfirmed" in title_lower:
                concepts["release_status"] = "UNCONFIRMED"
            else:
                concepts["release_status"] = "CONFIRMED"

        return concepts

    @staticmethod
    def _normalize_doc_type(value: str) -> str:
        value = value.upper().strip()
        return {"CT_0006":"CT_0006","TRANSFER ORDER":"CT_0006","0001":"0001","CT_0001":"0001","SALES ORDER":"0001"}.get(value, value)


class OMSXmlModifier:
    PLACEHOLDERS = {
        "ExtnWaveId":"${WaveId}",
        "ExtnTruckCapacity":"${TruckCapacity}",
        "ExtnRequestedDeliveryDate":"${ReqDeliveryDate}",
        "ExtnReservationStartTime":"${ReservationStartTime}",
        "ExtnReservationEndTime":"${ReservationEndTime}",
        "ExtnDeliveryWindowStartTime":"${WindowStartTime}",
        "ExtnDeliveryWindowEndTime":"${WindowEndTime}",
        "ExtnServiceArea":"${ServiceArea}",
        "ExtnDelServiceType":"${ServiceCarrier}",
        "ExtnServiceCarrier":"${ServiceCarrier}",
        "ExtnCustomerDesiredDateConfirmation":"Y",
        "OrderHeaderKey":"${OrderHeaderKey}",
        "OrderLineKey":"${OrderLineKey}",
        "OrderReleaseKey":"${OrderReleaseKey}",
        "ShipNode":"${ShipNode_Extracted}",
        "SCAC":"${SCAC_Extracted}",
        "CarrierServiceCode":"${CarrierServiceCode_Extracted}",
    }

    def apply_to_file(self, file_path: Path, api_name: str, concepts: Dict[str, Any]) -> bool:
        if not file_path.exists():
            return False
        text = file_path.read_text(encoding="utf-8")
        if file_path.suffix.lower() == ".json":
            modified = self._apply_json(text, api_name, concepts)
        else:
            modified = self._apply_xml(text, api_name, concepts)
        if modified != text:
            file_path.write_text(modified, encoding="utf-8")
            return True
        return False

    def apply_to_expected_result(self, file_path: Path, api_name: str, concepts: Dict[str, Any]) -> bool:
        if not file_path.exists():
            return False
        text = file_path.read_text(encoding="utf-8")
        if file_path.suffix.lower() == ".json":
            return False
        modified = self._apply_xml_expected(text, api_name, concepts)
        if modified != text:
            file_path.write_text(modified, encoding="utf-8")
            return True
        return False

    def _apply_xml_expected(self, xml: str, api: str, concepts: Dict[str, Any]) -> str:
        doc_type = self._resolve_doc_type(concepts)
        delivery_method = concepts.get("delivery_method", "SHP")
        base_drop_status = concepts.get("base_drop_status")

        if api == "createOrder":
            xml = self._set_attr(xml, r"<Order\b", "DocumentType", doc_type, count=1)
            xml = self._set_attr(xml, r"<OrderLine\b", "DeliveryMethod", delivery_method)
        elif api == "scheduleOrder":
            xml = self._set_attr(xml, r"<ScheduleOrder\b", "DocumentType", doc_type, count=1)
        elif api == "releaseOrder":
            xml = self._set_attr(xml, r"<ReleaseOrder\b", "DocumentType", doc_type, count=1)
        elif api == "CT069ForAutomationService":
            xml = self._set_attr(xml, r"<Order\b", "DocumentType", doc_type, count=1)
            xml = self._set_attr(xml, r"<OrderLine\b", "DeliveryMethod", delivery_method)
        elif api == "changeOrderStatus":
            xml = self._set_attr(xml, r"<OrderStatusChange\b", "DocumentType", doc_type, count=1)
            if base_drop_status:
                xml = self._set_attr(xml, r"<OrderStatusChange\b", "BaseDropStatus", base_drop_status, count=1)
        elif api == "getOrderReleaseList":
            xml = self._set_attr(xml, r"<OrderRelease\b", "DocumentType", doc_type, count=1)
        elif api == "orderEnquiry":
            xml = self._set_attr(xml, r"<Order\b", "DocumentType", doc_type, count=1)
        elif api == "createShipment":
            xml = self._set_attr(xml, r"<Shipment\b", "DocumentType", doc_type, count=1)
        elif api == "updateOrderFromRouting":
            xml = self._set_attr(xml, r"<Order\b", "DocumentType", doc_type, count=1)
        elif api == "orderAcknowledgement":
            xml = self._set_attr(xml, r"<Order\b", "DocumentType", doc_type, count=1)
        return xml

    def _apply_xml(self, xml: str, api: str, concepts: Dict[str, Any]) -> str:
        doc_type = self._resolve_doc_type(concepts)
        delivery_method = concepts.get("delivery_method", "SHP")
        release_status = concepts.get("release_status")
        base_drop_status = concepts.get("base_drop_status")
        is_transfer = doc_type == "CT_0006" or concepts.get("is_transfer_order")
        if api == "createOrder":
            xml = self._set_attr(xml, r"<Order\b", "DocumentType", doc_type, count=1)
            xml = self._set_attr(xml, r"<OrderLine\b", "DeliveryMethod", delivery_method)
            xml = self._inject_extn(xml, concepts)
        elif api == "scheduleOrder":
            xml = self._set_attr(xml, r"<ScheduleOrder\b", "DocumentType", doc_type, count=1)
        elif api == "releaseOrder":
            xml = self._set_attr(xml, r"<ReleaseOrder\b", "DocumentType", doc_type, count=1)
        elif api == "CT069ForAutomationService":
            xml = self._set_attr(xml, r"<Order\b", "DocumentType", doc_type, count=1)
            xml = self._set_attr(xml, r"<OrderLine\b", "DeliveryMethod", delivery_method)
            if release_status:
                xml = self._add_attr(xml, r"<Order\b", "ReleaseStatus", release_status, count=1)
            if "ExtnRequestedDeliveryDate" in concepts:
                xml = self._add_attr(xml, r"<Order\b", "ReqDeliveryDate", "${ReqDeliveryDate}", count=1)
            xml = self._inject_extn(xml, concepts)
        elif api == "changeOrderStatus":
            xml = self._set_attr(xml, r"<OrderStatusChange\b", "DocumentType", doc_type, count=1)
            if base_drop_status:
                xml = self._set_attr(xml, r"<OrderStatusChange\b", "BaseDropStatus", base_drop_status, count=1)
        elif api == "getOrderReleaseList":
            xml = self._set_attr(xml, r"<OrderRelease\b", "DocumentType", doc_type, count=1)
            if is_transfer:
                xml = self._set_attr(xml, r"<OrderRelease\b", "DocumentType", doc_type)
        elif api == "orderEnquiry":
            xml = self._set_attr(xml, r"<Order\b", "DocumentType", doc_type, count=1)
        elif api == "createShipment":
            xml = self._set_attr(xml, r"<Shipment\b", "DocumentType", doc_type, count=1)
        elif api == "updateOrderFromRouting":
            xml = self._set_attr(xml, r"<Order\b", "DocumentType", doc_type, count=1)
            xml = self._inject_extn(xml, concepts)
        elif api == "orderAcknowledgement":
            xml = self._set_attr(xml, r"<Order\b", "DocumentType", doc_type, count=1)
        return xml

    def _set_attr(self, xml: str, tag_pattern: str, attr: str, value: str, count: int = 0) -> str:
        regex = re.compile(rf'({tag_pattern}[^>]*?){attr}="[^"]*"', re.IGNORECASE)
        if regex.search(xml):
            repl = rf'\1{attr}="{value}"'
            if count:
                return regex.sub(repl, xml, count=count)
            return regex.sub(repl, xml)
        return self._add_attr(xml, tag_pattern, attr, value, count=count)

    def _add_attr(self, xml: str, tag_pattern: str, attr: str, value: str, count: int = 0) -> str:
        tag_regex = re.compile(rf'({tag_pattern})', re.IGNORECASE)
        m = tag_regex.search(xml)
        if m:
            pos = m.end(1)
            xml = xml[:pos] + f' {attr}="{value}"' + xml[pos:]
        return xml

    def _inject_extn(self, xml: str, concepts: Dict[str, Any]) -> str:
        for attr, placeholder in self.PLACEHOLDERS.items():
            if attr in concepts:
                pat = re.compile(rf'(<Extn\s[^>]*?){attr}="[^"]*"', re.IGNORECASE)
                if pat.search(xml):
                    xml = pat.sub(rf'\1{attr}="{placeholder}"', xml)
                else:
                    extn_pat = re.compile(r'(<Extn\s)', re.IGNORECASE)
                    m = extn_pat.search(xml)
                    if m:
                        pos = m.end(1)
                        xml = xml[:pos] + f'{attr}="{placeholder}" ' + xml[pos:]
                    else:
                        for insert_after in (r"(<Item\s)", r"(<OrderLine\s)", r"(<Order\s)"):
                            m2 = re.search(insert_after, xml, re.IGNORECASE)
                            if m2:
                                pos = m2.end(1)
                                xml = xml[:pos] + f'\n\t\t\t<Extn {attr}="{placeholder}" />' + xml[pos:]
                                break
        return xml

    def _apply_json(self, json_text: str, api: str, concepts: Dict[str, Any]) -> str:
        if api != "adjustInventory":
            return json_text
        try:
            data = json.loads(json_text)
            supplies = data.get("supplies", [{}])
            if supplies:
                supplies[0]["itemId"] = "${RandomId}"
                supplies[0]["shipNode"] = supplies[0].get("shipNode", "CT_Furniture_INC")
                supplies[0]["unitOfMeasure"] = supplies[0].get("unitOfMeasure", "EACH")
                supplies[0]["productClass"] = supplies[0].get("productClass", "GOOD")
                if "ExtnWaveId" in concepts:
                    supplies[0]["waveId"] = "${WaveId}"
                if "ExtnTruckCapacity" in concepts:
                    supplies[0]["truckCapacity"] = "${TruckCapacity}"
                data["supplies"] = supplies
            return json.dumps(data, indent=4, ensure_ascii=False)
        except (json.JSONDecodeError, TypeError):
            return json_text

    @staticmethod
    def _resolve_doc_type(concepts: Dict[str, Any]) -> str:
        return concepts.get("document_type", "0001")


class OMSTestMetadata:
    def __init__(self):
        self.concepts: Dict[str, Any] = {}
        self.csv_data: Dict[str, str] = {}
        self.step_mappings: List[Dict[str, Any]] = []
        self.xml_modifications: List[Dict[str, str]] = []

    def build(self, tc: Dict[str, str], step_mappings: List[Dict]) -> Dict[str, Any]:
        extractor = OMSConceptExtractor()
        self.concepts = extractor.extract_from_test_case(tc)
        self.csv_data = tc
        self.step_mappings = step_mappings
        return {
            "csv": self.csv_data,
            "oms_concepts": self.concepts,
            "api_step_mapping": self.step_mappings,
            "xml_modifications": self.xml_modifications,
            "generated_at": __import__("datetime").datetime.now().isoformat(),
        }

    def record_modification(self, file_name: str, api: str):
        self.xml_modifications.append({"file": file_name, "api": api})

    def save_complete(self, output_path: Path, tc: Dict[str, str], step_mappings: List[Dict]):
        data = self.build(tc, step_mappings)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(
            json.dumps(data, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
