require('../lib/HttpsCreditCardService.rb')

url = "https://test.salt.com/gateway/creditcard/processor.do"
merchantId = [your merchant Id]
apiToken = "apiToken"

merchant = Merchant.new(merchantId, apiToken)
service = HttpsCreditCardService.new(merchant, url)
creditCard = CreditCard.new("4242424242424242", "1212", "111", "123 Street", "A1B2C3")
schedule = Schedule.new($WEEK, 5)

periodicPurchaseInfo = PeriodicPurchaseInfo.new(nil, $IN_PROGRESS, schedule, "60000" , "recurring-order 1" ,nil,"111111", "121111")
#:periodicTransactionId, :state, :schedule, :perPaymentAmount, :orderId, :customerId, :startDate, :endDate, :nextPaymentDate, :lastPaymentId
#receipt = service.updateRecurringPurchase2(periodicPurchaseInfo, creditCard, nil)
receipt = service.recurringPurchase2(periodicPurchaseInfo, nil, nil)
#receipt = service.verifyTransaction("51611", nil)
#receipt = service.cancelRecurringPurchase(periodicPurchaseInfo.periodicTransactionId)


def to_print(value)
	@value = value
	if @value !=nil
		print @value + "\n"
	else
		print "<null>\n"
	end
end

approved = receipt.isApproved
errorCode = receipt.getErrorCode
errorMessage = receipt.getErrorMessage
debugMessage = receipt.getDebugMessage
approvalInfo = receipt.getApprovalInfo


puts "Approved: "+"#{approved}"
print "Error Code: "
to_print(errorCode)
print "Error Message: "
to_print(errorMessage)
print "Debug Message: "
to_print(debugMessage)
if approvalInfo !=nil

	amount = approvalInfo.getAuthorizedAmount
	approvalCode = approvalInfo.getApprovalCode
	traceNumber = approvalInfo.getTraceNumber
	referenceNumber = approvalInfo.getReferenceNumber

	puts "Approval Info: "	
	puts "Authorized Amount: #{amount}"
	puts "Approval Code: #{approvalCode}"
	puts "Trace Number: #{traceNumber}"
	puts "Reference Number: #{referenceNumber}"
end

avsResponse = receipt.getAvsResponse
cvv2Response = receipt.getCvv2Response
orderId = receipt.getOrderId
transactionId = receipt.getTransactionId
processedDateTime = receipt.getProcessedDateTime.to_s
periodicPurchaseInfo = receipt.getPeriodicPurchaseInfo


print "Avs Response: "
if avsResponse !=nil
	avsResponseCode = avsResponse.avsResponseCode
	avsErrorCode = avsResponse.avsErrorCode
	avsErrorMessage = avsResponse.avsErrorMessage
	zipType = avsResponse.zipType
	streetMatched = avsResponse.streetMatched
	zipMatched = avsResponse.zipMatched
	isStreetFormatValid = avsResponse.isStreetFormatValid
	isStreetFormatValidAndMatched = avsResponse.isStreetFormatValidAndMatched
	isZipFormatValid = avsResponse.isZipFormatValid
	isZipFormatValidAndMatched = avsResponse.isZipFormatValidAndMatched

	print "Avs Response Code: "
	to_print(avsResponseCode)
	print "Avs Error Code: "
	to_print(avsErrorCode)
	print "Avs Error Message: "
	to_print(avsErrorMessage)
	print "Zip Type: "
	to_print(zipType)
	print"Zip Valid: "
	to_print(isZipFormatValid)
	print "Zip Matched: "
	to_print(zipMatched)
	print "Zip Valid and Matched: "
	to_print(isZipFormatValidAndMatched)
	print "Street Valid: "
	to_print(isStreetFormatValid)
	print "Street Matched: "
	to_print(streetMatched)
	print "Street Valid + Matched: "
	to_print(isStreetFormatValidAndMatched)	
end

print "Cvv2 Response: "
to_print(cvv2Response)
print "Order Id: "
to_print(orderId)
print "Processed Date Time: "
to_print(processedDateTime)
print "Transaction Id: "
to_print(transactionId)

if periodicPurchaseInfo != nil
	ppTransactionId = periodicPurchaseInfo.periodicTransactionId
	state = periodicPurchaseInfo.state
	schedule = periodicPurchaseInfo.schedule
	perPaymentAmount = periodicPurchaseInfo.perPaymentAmount
	customerId = periodicPurchaseInfo.customerId
	puts "Periodic Purchase Info: "
	print "PP Transaction Id: "
	to_print(ppTransactionId)
	print "State: "
	to_print(state)
	print "Schedule: "
	if schedule!=nil
		scheduleType = schedule.scheduleType
		scheduleLength = schedule.intervalLength
		print "\nSchedule Type: "
		to_print(scheduleType)
		print "Schedule Length: "
		to_print(scheduleLength)
	else
		prints "<null>\n"
	end
	puts "Per Payment Amount: " 
	to_print(perPaymentAmount)
	puts "Customer Id: " 
	to_print(customerId)
end
