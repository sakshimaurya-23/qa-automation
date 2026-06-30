# *** Settings ***
# Library      ../Scripts/env_variables.py

# *** Variables ***


# ${CUR_DIR}     ${CURDIR}
# ${JSON_FILE1}    updated_files.json
# ${output_foldername}    /Data/Output/
# ${actualresult_foldername}    actualresult
# ${actualresult_file_extension}    .xml
# ${user}             admin
# ${passwd}           password
# &{headers}          Content-Type=application/xml  Authorization=Basic YWRtaW46cGFzc3dvcmQ=
# ${auth}=  Create List  ${user}  ${passwd}
# ${multiApi}             multiApi
# #${base_url}     http://9.30.26.220:9080
# ${base_url}    https://cityf-dev-1.oms.supply-chain.ibm.com
# #${base_url}    https://cityf-qa-1.oms.supply-chain.ibm.com
# ${req_uri}      /smcfs/interop/InteropHttpServlet
# ${INPUT_DIR}    \\Input\\
# ${SETUP_DIR}    \\setup\\

# #compare xmls
# ${EXPECTED_XML_FILE}    /expectedResult/expected_result
# ${ACTUAL_XML_FILE}      /output/actual_result
# ${Expected_Result}    /expectedResult/expected_result.xml
# ${ActualResult}        /Output/actual_result.xml
# ${expected_result_file}    /ExpectedResult/expectedresult
# ${actual_result_file}    /ActualResult/actualresult


# #IV testing tokens
# ${dev_b_token}    Bearer 75siI7luCAnujXoi3vP0XtkiKgSBw09l
# ${dev_b_server}    https://api.watsoncommerce.ibm.com

# #IV testing urls
# ${getItemDetailsTemp}    /catalog/us-1b8d5331/v1/itemDetails?itemId=tagControlled_3&unitOfMeasure=EACH
# ${getItemDetailsForML}    /catalog/us-1b8d5331/v1/itemDetails/mget
# ${adjustSupply}     https://api.watsoncommerce.ibm.com/inventory/us-1b8d5331/v1/supplies
# ${upsertItems}     https://api.watsoncommerce.ibm.com/catalog/us-1b8d5331/v1/items
# ${getSupplyTemp}     /inventory/us-1b8d5331/v1/supplies?unitOfMeasure=EACH&productClass=GOOD&shipNode=1&itemId=tagControlled_3

# #FileNames
# ${createOrder_Input_file_Name}    createOrder
# ${createOrder_Input_file_Name1}    createOrder1
# ${scheduleOrder_Input_file_Name}    scheduleOrder
# ${releaseOrder_Input_file_Name}    releaseOrder
# ${getOrderDetails_Input_file_Name}    getOrderDetails
# ${confirmShipment_Input_file_Name}    confirmShipment
# ${manageItem_Input_file_Name}    manageItem
# ${deleteOrder_Input_file_Name}    deleteOrder
# ${getOrderReleaseList_Input_file_Name}    getOrderReleaseList
# ${changeOrderStatus_Input_file_Name}    changeOrderStatus
# ${createShipment_Input_file_Name}    createShipment
# ${getCustomerList_Input_file_Name}    getCustomerList
# ${manageCustomerList_Input_file_Name}    manageCustomer
# ${manageItem_MultiAPi_Input_file_Name}    manageItem
# ${getATPForNearestStores_Input_file_Name}    getATPForNearestStores
# ${getATPForNearestStores_Input_file_Name1}    getATPForNearestStores1
# ${orderDetails_Input_file_Name}    orderDetails_input

# ${DateRange_orderStatusInquiry_file_Name}    orderStatusInquiryDateRange
# ${OrdNo_orderStatusInquiry_file_Name}  ordNoOrderStatusInquiry
# ${OrdNoAndDateRange_orderStatusInquiry_file_Name}    orderStatusInquiryOrdNoDateRange
# ${ExcludeCancelled_orderStatusInquiry_file_Name}    orderStatusInquiryExcludeCancelled
# ${MaxRecords_orderStatusInquiry_file_Name}    orderStatusInquiryMaxRecords
# ${CustomerFirstName_orderStatusInquiry_file_Name}  customerFirstNameOrderStatusInquiry
# ${CustomerLastName_orderStatusInquiry_file_Name}  customerLastNameOrderStatusInquiry
# ${CustomerEMailID_orderStatusInquiry_file_Name}  customerEMailIDOrderStatusInquiry
# ${MultipleCustomerFields_orderStatusInquiry_file_Name}  multipleCustomerFieldsOrderStatusInquiry
# ${ExtnHasPaymentAppDocuments_orderStatusInquiry_file_Name}  orderStatusInquiryExtnHasPaymentAppDocuments
# ${CombinedFiltersWithOrderNumber_orderStatusInquiry_file_Name}  orderStatusInquiryCombinedFiltersWithOrderNumber
# ${CombinedFiltersWithCustomerInfoOrderStatusInquiry_file_Name}   combinedFiltersWithCustomerInfoOrderStatusInquiry
# ${ShipDepart_SingleLine_TotalQty}    SingleLineTotalQty
# ${ShipDepart_SingleLine_ShortageQty}    SingleLineShortageQty
# ${ShipDepart_MultiLine_ShortageQtyAndTotalQty}    MultiLineShortageQtyLine1TotalQtyLine2
# ${ShipDepart_MultiLine_Line1and2TotalQty}    MultiLineLine1and2TotalQty
# ${updateOrderLine_Input_file_Name}    UpdateOLToReadyToShip
# ${SendOrderLine_Input_file_Name}    CTSendOrderLineListForRouting
# ${createOrder_Input_file_Name_INT069_01}    createOrderTC001
# ${createOrder_Input_file_Name_INT069_02}    createOrderTC002
# ${createOrder_Input_file_Name_INT069_03}    createOrderTC003
# ${createOrder_Input_file_Name_INT069_04}    createOrderTC004
# ${createOrder_Input_file_Name_INT069_05}    createOrderTC005
# ${createOrder_Input_file_Name_INT069_06}    createOrderTC006
# ${createOrder_Input_file_Name_INT069_07}    createOrderTC007
# ${createOrder_Input_file_Name_INT069_08}    createOrderTC008
# ${createOrder_Input_file_Name_INT069_09}    createOrderTC009
# ${createOrder_Input_file_Name_INT069_10}    createOrderTC010
# ${createOrder_Input_file_Name_INT069_11}    createOrderTC011
# ${GDO_CLR_1_Input_File_Name}    CTGetDOFClearance1
# ${GDO_CLR_2_Input_File_Name}    CTGetDOFClearance2
# ${GDO_CLR_3_Input_File_Name}    CTGetDOFClearance3
# ${GDO_CLR_4_Input_File_Name}    CTGetDOFClearance4
# ${GDO_CLR_5_Input_File_Name}    CTGetDOFClearance5
# ${GDO_CLR_6_Input_File_Name}    CTGetDOFClearance6
# ${GDO_Floor_Input_File_Name}    CTGetDOFFloorModel
# ${GDO_Special49_Input_File_Name}    CTGetDOFSpecialNode49
# ${GDO_SpecialNot_YN_49_Input_File_Name}    CTGetDOFSpecialNot49YN
# ${GDO_SpecialNot_YY_49_Input_File_Name}    CTGetDOFSpecialNot49YY
# ${GDO_NationWide_Input_File_Name}    CTGetDOFNationWide
# ${GDO_Export_Input_File_Name}    CTGetDOFExport
# ${GDO_NOCartType_Input_File_Name}    CTGetDOFNoCartType
# ${CTOrderRouting_CONFIRMED_Y}    CTOrderRouting_CONFIRMED_Y
# ${createOrder_Input_TwoLines_2060}    createOrder_TwoLines_2060
# ${createOrder_Input_TwoLines_1500_appt}    createOrder_TwoLines_1500_appt
# ${CTOrderRouting_UNSCHEDULED_N}    CTOrderRouting_UNSCHEDULED_N
# ${CTOrderRouting_UNSCHEDULED_Y}    CTOrderRouting_UNSCHEDULED_Y
# ${CTOrderRouting_UNCONFIRMED_N}    CTOrderRouting_UNCONFIRMED_N
# ${CTOrderRouting_UNCONFIRMED_Y}    CTOrderRouting_UNCONFIRMED_Y
# ${CTOrderRouting_CONFIRMED_N}    CTOrderRouting_CONFIRMED_N
# ${createOrder_Input_APTO_And_Scheduled}    createOrder_2060_And_1500
# ${createOrder_2060_RDD_Plus2Days}    createOrder_2060_RDD_Plus2Days
# ${createOrder_SplitRelease_OrderRouting}    createOrder_SplitRelease_OrderRouting
# ${createOrder_SplitRelease_OrderRouting_2}    createOrder_SplitRelease_OrderRouting_2
# ${CTOrderRouting_Split_CONFIRMED_Y}    CTOrderRouting_Split_CONFIRMED_Y
# ${CTOrderRouting_Split_CONFIRMED_N}    CTOrderRouting_Split_CONFIRMED_N
# ${CTOrderRouting_Split_UNCONFIRMED_N}    CTOrderRouting_Split_UNCONFIRMED_N
# ${CTOrderRouting_Split_UNCONFIRMED_Y}    CTOrderRouting_Split_UNCONFIRMED_Y
# ${CTOrderRouting_Split_UNSCHEDULED_N}    CTOrderRouting_Split_UNSCHEDULED_N
# ${createOrder_TO}    createOrder_TO
# ${createOrder_OneOrder_TwoReleases_TwoLines}    createOrder_OneOrder_TwoReleases_TwoLines
# ${createOrder_ThreeLines_SameWaveID}    createOrder_ThreeLines_SameWaveID
# ${createOrder_TwoLines_MixedShipNodes_1500_2060}    createOrder_TwoLines_MixedShipNodes_1500_2060
# ${createOrderMultiLine_29}    createOrderMultiLine
# ${createOrderPick_29}    createOrderPick
# ${createOrderSHP_29}    createOrderSHP
# ${PICKNoMarkForOrderSUCCESS_29}    PICKNoMarkForOrderSUCCESS
# ${PickOrderFailure_29}    PickOrderFailure
# ${PICKWithMarkForOrderSUCCESS_29}    PICKWithMarkForOrderSUCCESS
# ${SHPOrderFailure_29}    SHPOrderFailure
# ${SHPOrderNoShipToSUCCESS_29}    SHPOrderNoShipToSUCCESS
# ${SHPOrderWithShipToSUCCESS_29}    SHPOrderNoShipToSUCCESS


*** Settings ***
Library      ../Scripts/env_variables.py

*** Variables ***


${CUR_DIR}     ${CURDIR}
${JSON_FILE1}    updated_files.json
${output_foldername}    /Data/Output/
${actualresult_foldername}    actualresult
${actualresult_file_extension}    .xml
${user}             admin
${passwd}           password
&{headers}          Content-Type=application/xml  Authorization=Basic YWRtaW46cGFzc3dvcmQ=
${auth}=  Create List  ${user}  ${passwd}
${multiApi}             multiApi
#${base_url}     http://9.30.26.220:9080
${base_url}    https://cityf-dev-1.oms.supply-chain.ibm.com
#${base_url}    https://cityf-qa-1.oms.supply-chain.ibm.com
${req_uri}      /smcfs/interop/InteropHttpServlet
${INPUT_DIR}    \\Input\\
${SETUP_DIR}    \\setup\\

#compare xmls
${EXPECTED_XML_FILE}    /Data/expectedResult/expected_result
${ACTUAL_XML_FILE}      /Data/Output/actual_result
${Expected_Result}    /Data/expectedResult/expected_result.xml
${ActualResult}        /Data/Output/actual_result.xml
${expected_result_file}    /Data/ExpectedResult/expectedresult
${actual_result_file}    /Data/ActualResult/actualresult


#IV testing tokens
${dev_b_token}    Bearer y4dUjq0xD9kDOVI74tobHwnbrWpBmyPe
${dev_b_server}    https://api.watsoncommerce.ibm.com

#IV testing urls
${getItemDetailsTemp}    /catalog/us-1b8d5331/v1/itemDetails?itemId=tagControlled_3&unitOfMeasure=EACH
${getItemDetailsForML}    /catalog/us-1b8d5331/v1/itemDetails/mget
${adjustSupply}     https://api.watsoncommerce.ibm.com/inventory/us-1b8d5331/v1/supplies
${upsertItems}     https://api.watsoncommerce.ibm.com/catalog/us-1b8d5331/v1/items
${getSupplyTemp}     /inventory/us-1b8d5331/v1/supplies?unitOfMeasure=EACH&productClass=GOOD&shipNode=1&itemId=tagControlled_3

#FileNames
${createOrder_Input_file_Name}    createOrder
${createOrder_Input_file_Name1}    createOrder1
${scheduleOrder_Input_file_Name}    scheduleOrder
${releaseOrder_Input_file_Name}    releaseOrder
${getOrderDetails_Input_file_Name}    getOrderDetails
${confirmShipment_Input_file_Name}    confirmShipment
${manageItem_Input_file_Name}    manageItem
${deleteOrder_Input_file_Name}    deleteOrder
${getOrderReleaseList_Input_file_Name}    getOrderReleaseList
${changeOrderStatus_Input_file_Name}    changeOrderStatus
${createShipment_Input_file_Name}    createShipment
${getCustomerList_Input_file_Name}    getCustomerList
${manageCustomerList_Input_file_Name}    manageCustomer
${manageItem_MultiAPi_Input_file_Name}    manageItem
${getATPForNearestStores_Input_file_Name}    getATPForNearestStores
${getATPForNearestStores_Input_file_Name1}    getATPForNearestStores1
${orderDetails_Input_file_Name}    orderDetails_input

${DateRange_orderStatusInquiry_file_Name}    orderStatusInquiryDateRange
${OrdNo_orderStatusInquiry_file_Name}  ordNoOrderStatusInquiry
${OrdNoAndDateRange_orderStatusInquiry_file_Name}    orderStatusInquiryOrdNoDateRange
${ExcludeCancelled_orderStatusInquiry_file_Name}    orderStatusInquiryExcludeCancelled
${MaxRecords_orderStatusInquiry_file_Name}    orderStatusInquiryMaxRecords
${CustomerFirstName_orderStatusInquiry_file_Name}  customerFirstNameOrderStatusInquiry
${CustomerLastName_orderStatusInquiry_file_Name}  customerLastNameOrderStatusInquiry
${CustomerEMailID_orderStatusInquiry_file_Name}  customerEMailIDOrderStatusInquiry
${MultipleCustomerFields_orderStatusInquiry_file_Name}  multipleCustomerFieldsOrderStatusInquiry
${ExtnHasPaymentAppDocuments_orderStatusInquiry_file_Name}  orderStatusInquiryExtnHasPaymentAppDocuments
${CombinedFiltersWithOrderNumber_orderStatusInquiry_file_Name}  orderStatusInquiryCombinedFiltersWithOrderNumber
${CombinedFiltersWithCustomerInfoOrderStatusInquiry_file_Name}   combinedFiltersWithCustomerInfoOrderStatusInquiry
${ShipDepart_SingleLine_TotalQty}    SingleLineTotalQty
${ShipDepart_SingleLine_ShortageQty}    SingleLineShortageQty
${ShipDepart_MultiLine_ShortageQtyAndTotalQty}    MultiLineShortageQtyLine1TotalQtyLine2
${ShipDepart_MultiLine_Line1and2TotalQty}    MultiLineLine1and2TotalQty
${updateOrderLine_Input_file_Name}    UpdateOLToReadyToShip
${SendOrderLine_Input_file_Name}    CTSendOrderLineListForRouting
${createOrder_Input_file_Name_INT069_01}    createOrderTC001
${createOrder_Input_file_Name_INT069_02}    createOrderTC002
${createOrder_Input_file_Name_INT069_03}    createOrderTC003
${createOrder_Input_file_Name_INT069_04}    createOrderTC004
${createOrder_Input_file_Name_INT069_05}    createOrderTC005
${createOrder_Input_file_Name_INT069_06}    createOrderTC006
${createOrder_Input_file_Name_INT069_07}    createOrderTC007
${createOrder_Input_file_Name_INT069_08}    createOrderTC008
${createOrder_Input_file_Name_INT069_09}    createOrderTC009
${createOrder_Input_file_Name_INT069_10}    createOrderTC010
${createOrder_Input_file_Name_INT069_11}    createOrderTC011
${GDO_CLR_1_Input_File_Name}    CTGetDOFClearance1
${GDO_CLR_2_Input_File_Name}    CTGetDOFClearance2
${GDO_CLR_3_Input_File_Name}    CTGetDOFClearance3
${GDO_CLR_4_Input_File_Name}    CTGetDOFClearance4
${GDO_CLR_5_Input_File_Name}    CTGetDOFClearance5
${GDO_CLR_6_Input_File_Name}    CTGetDOFClearance6
${GDO_Floor_Input_File_Name}    CTGetDOFFloorModel
${GDO_Special49_Input_File_Name}    CTGetDOFSpecialNode49
${GDO_SpecialNot_YN_49_Input_File_Name}    CTGetDOFSpecialNot49YN
${GDO_SpecialNot_YY_49_Input_File_Name}    CTGetDOFSpecialNot49YY
${GDO_NationWide_Input_File_Name}    CTGetDOFNationWide
${GDO_Export_Input_File_Name}    CTGetDOFExport
${GDO_NOCartType_Input_File_Name}    CTGetDOFNoCartType
${CTOrderRouting_CONFIRMED_Y}    CTOrderRouting_CONFIRMED_Y
${createOrder_Input_TwoLines_2060}    createOrder_TwoLines_2060
${createOrder_Input_TwoLines_1500_appt}    createOrder_TwoLines_1500_appt
${CTOrderRouting_UNSCHEDULED_N}    CTOrderRouting_UNSCHEDULED_N
${CTOrderRouting_UNSCHEDULED_Y}    CTOrderRouting_UNSCHEDULED_Y
${CTOrderRouting_UNCONFIRMED_N}    CTOrderRouting_UNCONFIRMED_N
${CTOrderRouting_UNCONFIRMED_Y}    CTOrderRouting_UNCONFIRMED_Y
${CTOrderRouting_CONFIRMED_N}    CTOrderRouting_CONFIRMED_N
${createOrder_Input_APTO_And_Scheduled}    createOrder_2060_And_1500
${createOrder_2060_RDD_Plus2Days}    createOrder_2060_RDD_Plus2Days
${createOrder_SplitRelease_OrderRouting}    createOrder_SplitRelease_OrderRouting
${createOrder_SplitRelease_OrderRouting_2}    createOrder_SplitRelease_OrderRouting_2
${CTOrderRouting_Split_CONFIRMED_Y}    CTOrderRouting_Split_CONFIRMED_Y
${CTOrderRouting_Split_CONFIRMED_N}    CTOrderRouting_Split_CONFIRMED_N
${CTOrderRouting_Split_UNCONFIRMED_N}    CTOrderRouting_Split_UNCONFIRMED_N
${CTOrderRouting_Split_UNCONFIRMED_Y}    CTOrderRouting_Split_UNCONFIRMED_Y
${CTOrderRouting_Split_UNSCHEDULED_N}    CTOrderRouting_Split_UNSCHEDULED_N
${createOrder_TO}    createOrder_TO
${createOrder_OneOrder_TwoReleases_TwoLines}    createOrder_OneOrder_TwoReleases_TwoLines
${createOrder_ThreeLines_SameWaveID}    createOrder_ThreeLines_SameWaveID
${createOrder_TwoLines_MixedShipNodes_1500_2060}    createOrder_TwoLines_MixedShipNodes_1500_2060
${createOrderMultiLine_29}    createOrderMultiLine
${createOrderPick_29}    createOrderPick
${createOrderSHP_29}    createOrderSHP
${PICKNoMarkForOrderSUCCESS_29}    PICKNoMarkForOrderSUCCESS
${PickOrderFailure_29}    PickOrderFailure
${PICKWithMarkForOrderSUCCESS_29}    PICKWithMarkForOrderSUCCESS
${SHPOrderFailure_29}    SHPOrderFailure
${SHPOrderNoShipToSUCCESS_29}    SHPOrderNoShipToSUCCESS
${SHPOrderWithShipToSUCCESS_29}    SHPOrderNoShipToSUCCESS
