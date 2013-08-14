require ('../lib/HttpsCreditCardService.rb')

url = "https://test.salt.com/gateway/creditcard/processor.do"
merchantId = [your merchantId]
apiToken = "[your apiToken]"
service = HttpsCreditCardService.new(merchantId, apiToken, url)

creditCard = CreditCard.new('5555555555554444', '1010', '111', '123 Street', 'A1B23C');

paymentProfile = PaymentProfile.new(creditCard, nil)

storageToken = "my-token-010"
receipt = service.addToStorage(storageToken, paymentProfile)


puts "storage Approved: " + "#{receipt.isApproved()}"
if receipt.isApproved == false
puts receipt.getErrorCode()
puts receipt.getErrorMessage()

elsif (receipt.isApproved()!=false)
	response = service.singlePurchase("stored-card-003", storageToken, "100", nil)
	puts "\n"
	puts "Single Purchase with stored card results: "
	if (response.isApproved() == false)
		puts response.errorCode
		puts response.errorMessage
		puts response.debugMessage
	else
		puts response.getApprovalInfo().authorizedAmount
		puts response.getApprovalInfo().approvalCode
	end
	
else
	puts service.errorCode
	puts service.errorMsg
end

