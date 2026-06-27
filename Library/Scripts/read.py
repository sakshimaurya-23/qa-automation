import csv

def append_excel_file1(file_name1,order_no,test_name,timeStamp,inputXML,outputXML):
    with open(file_name1, 'a', newline='') as csvfile:
        writer = csv.writer(csvfile)  # getting a csv.writer object
        csvdata = (test_name,timeStamp,order_no,inputXML,outputXML)
        #csvdata1 = ('TestCaseName', test_name)
        writer.writerow(csvdata)  # appending a line to the end file. csvdata is a tuple
        #writer.writerow(csvdata1)