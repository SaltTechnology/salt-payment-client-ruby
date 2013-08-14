require('./DataClasses.rb')
require 'cgi'
require 'net/http'
require 'net/https'
# require 'logger'

# $log = Logger.new('log.txt')
class HttpsCreditCardService
	attr_reader :errorMsg
	attr_reader :errorCode
  
	def initialize(*args)
		@marketSegment = $MARKET_SEGMENT_INTERNET
		
		# HttpsCreditCardService (merchant, url)
		if args.size == 2
			@merchant = args[0]
			@url = args[1]
		else
		
		# HttpsCreditCardService (merchantId, apiToken, url)
			@merchantId = args[0]
			@apiToken = args[1]
			@url = args[2]
			@merchant = Merchant.new(@merchantId, @apiToken)
		end
	end
  
	def refund(purchaseId, purchaseOrderId, refundOrderId, amount)		
		if purchaseOrderId == nil
			raise InvalidRequest, "purchaseOrderId is required"
		end
		
		req = Hash::new
	
		appendHeader(req, "refund")
		appendTransactionId(req, purchaseId)
		appendTransactionOrderId(req, purchaseOrderId)
		if refundOrderId !=nil
			appendOrderId(req, refundOrderId)
		end
		appendAmount(req, amount)
		return send(req, "creditcard")
	end
  
	def singlePurchase(orderId, creditCardSpecifier, amount, verificationRequest)
		if creditCardSpecifier == nil
			raise InvalidRequest, "creditcard or storageTokenId is required"
		end
			if orderId == nil				
			raise InvalidRequest, "orderId is required"
		end			
			req = Hash::new
		
		appendHeader(req, "singlePurchase")
		appendOrderId(req, orderId)		
		if creditCardSpecifier.is_a?(String)
		  appendStorageTokenId(req, creditCardSpecifier)
		else
		  appendCreditCard(req, creditCardSpecifier)
		end		
		appendAmount(req, amount)
		appendVerificationRequest(req, verificationRequest)
		return send(req, "creditcard")
		end
  
	def installmentPurchase(orderId, creditCard, preinstallmentamount, startDate, totalNumberInstallments, verificationRequest)
		if orderId == nil
		  raise InvalidRequest, "orderId is required"
		end
	
		if creditCard == nil
		  raise InvalidRequest, "creditCard is required"
		end
	
		req = Hash::new
		
		appendHeader(req, "installmentPurchase")
		appendOrderId(req, orderId)
		appendCreditCard(req, creditCard)
		appendAmount(req, preinstallmentamount)
		appendStartDate(req, startDate)
		appendTotalNumberInstallments(req, totalNumberInstallments)
		appendVerificationRequest(req, verificationRequest)
		
		return send(req, "creditcard")
	end
	
	def recurringPurchase(orderId, creditCardSpecifier, perPaymentAmount, startDate, endDate, schedule, verificationRequest)
		if orderId == nil
			raise InvalidRequest, "orderId is required"
		end
		periodicPurchaseInfo = PeriodicPurchaseInfo.new(nil,nil,schedule, perPaymentAmount, orderId, nil, startDate, endDate, nil)
		
		return recurringPurchaseHelper(periodicPurchaseInfo, creditCardSpecifier, verificationRequest)
	end
  
	def recurringPurchase2(periodicPurchaseInfo, creditCardSpecifier, verificationRequest)
		if periodicPurchaseInfo.orderId == nil
			raise InvalidRequest, "orderId is required"
		end
		return recurringPurchaseHelper(periodicPurchaseInfo, creditCardSpecifier, verificationRequest)
	end
	
	def recurringPurchaseHelper(periodicPurchaseInfo, creditCardSpecifier, verificationRequest)
		if creditCardSpecifier == nil
			raise InvalidRequest, "creditcard or storageTokenId is required"
		end
		
		req = Hash::new
		appendHeader(req, "recurringPurchase")
		appendOperationType(req, "create")
		appendPeriodicPurchaseInfo(req, periodicPurchaseInfo)
		appendVerificationRequest(req, verificationRequest)
		
		if creditCardSpecifier.is_a?(String)
			appendStorageTokenId(req, creditCardSpecifier)
			return send(req, "storage")
		else
			appendCreditCard(req, creditCardSpecifier)
			return send(req, "creditcard")
		end
	end
	
	def holdRecurringPurchase(recurringPurchaseId)
		periodicPurchaseInfo = PeriodicPurchaseInfo.new(recurringPurchaseId, $ON_HOLD, nil, nil, nil, nil, nil, nil, nil)
		return updateRecurringPurchaseHelper(periodicPurchaseInfo, nil, nil)
	end
  
	def resumeRecurringPurchase(recurringPurchaseId)
		periodicPurchaseInfo = PeriodicPurchaseInfo.new(recurringPurchaseId, $IN_PROGRESS, nil, nil, nil, nil, nil, nil, nil)
		return updateRecurringPurchaseHelper(periodicPurchaseInfo, nil, nil)
	end
  
	def cancelRecurringPurchase(recurringPurchaseId)
		periodicPurchaseInfo = PeriodicPurchaseInfo.new(recurringPurchaseId, $CANCELLED, nil, nil, nil, nil, nil, nil, nil)
		return updateRecurringPurchaseHelper(periodicPurchaseInfo, nil, nil)
	end
  
	def queryRecurringPurchase(recurringPurchaseId)
		if recurringPurchaseId == nil
		  raise InvalidRequest, "recurringPurchaseId is required"
		end
		
		req = Hash::new		
		appendHeader(req, "recurringPurchase")
		appendOperationType(req, "query")
		appendTransactionId(req, recurringPurchaseId)
		
		return send(req, "creditcard")
	end
  
	def updateRecurringPurchase(recurringPurchaseId, creditCardSpecifier, perPaymentAmount, verificationRequest, state)    
		if recurringPurchaseId == nil
			raise InvalidRequest, "recurringPurchaseId is required"
		end
		periodicPurchaseInfo = PeriodicPurchaseInfo.new(recurringPurchaseId, state, nil, perPaymentAmount, nil, nil, nil, nil, nil)
		return updateRecurringPurchaseHelper(periodicPurchaseInfo, creditCardSpecifier, verificationRequest)
	end
	
	def updateRecurringPurchase2(periodicPurchaseInfo, creditCardSpecifier, verificationRequest)
		if (periodicPurchaseInfo.periodicTransactionId == nil)
			raise InvalidRequest, "recurringPurchaseId is required"
		end
		return updateRecurringPurchaseHelper(periodicPurchaseInfo, creditCardSpecifier, verificationRequest)
	end
	
	def updateRecurringPurchaseHelper(periodicPurchaseInfo, creditCardSpecifier, verificationRequest)
		req = Hash::new
		appendHeader(req, "recurringPurchase")
		appendOperationType(req, "update")
		appendTransactionId(req, periodicPurchaseInfo.periodicTransactionId)
		if verificationRequest != nil
			appendVerificationRequest(req, verificationRequest)
		end
		appendPeriodicPurchaseInfo(req, periodicPurchaseInfo)
		if creditCardSpecifier !=nil
			if creditCardSpecifier.is_a?(String)
				appendStorageTokenId(req, creditCardSpecifier)
				return send(req, "storage")
			else
				appendCreditCard(req, creditCardSpecifier)
			end
		end
		send(req,"creditcard")
	end
	
	def verifyCreditCard(creditCardSpecifier, verificationRequest)
		if creditCardSpecifier == nil
			raise InvalidRequest, "credit card or storageTokenId is required"
		end
		
		if verificationRequest == nil
			raise InvalidRequest, "verificationRequest is required"
		end
		
		req = Hash::new
		appendHeader(req, "verifyCreditCard")
		if creditCardSpecifier.is_a?(String)
			appendStorageTokenId(req, creditCardSpecifier)
		else
			appendCreditCard(req, creditCardSpecifier)
		end
		appendVerificationRequest(req, verificationRequest)
		return send(req, "creditcard")
	end
	
	def voidTransaction(transactionId, transactionOrderId)
		if transactionOrderId == nil
			raise InvalidRequest, "transactionOrderId is required"
		end
		req = Hash::new
		appendHeader(req, "void")
		appendTransactionId(req, transactionId)
		appendTransactionOrderId(req, transactionOrderId)
		return send(req, "creditcard")
	end
	
	def verifyTransaction(transactionId, transactionOrderId)
	
		if (transactionOrderId == nil || transactionId == nil)
			raise InvalidRequest, "either transactionId or transactionOrderId is required"
		end
		
		req = Hash::new
		appendHeader(req, "verifyTransaction")
		if (transactionId != nil)
			appendTransactionId(req, transactionId)
		end
		if (transactionOrderId != nil)
			appendTransactionOrderId(req, transactionOrderId)
		end
		return send(req, "creditcard")
	end
	
	def addToStorage(storageTokenId, paymentProfile)
		if (paymentProfile == nil)
			raise InvalidRequest, "payment profile is required"
		end
		
		req = Hash::new
		
		appendHeader(req, "secureStorage")
		appendOperationType(req, "create")
		appendStorageTokenId(req, storageTokenId)
		appendPaymentProfiles(req, paymentProfile)
		return send(req, "storage")
	end
	
	def deleteFromStorage(storageTokenId)
		if storageTokenId == nil
			raise InvalidRequest, "storageTokenId is required"
		end
		
		req = Hash::new
		appendHeader(req, "secureStorage")
		appendOperationType(req, "delete")
		appendStorageTokenId(req, storageTokenId)
		return send(req, "storage")
	end
	
	def queryStorage(storageTokenId)
		if storageTokenId == nil
			raise InvalidRequest, "storageTokenId is required"
		end
		
		req = Hash::new
		appendHeader(req, "secureStorage")
		appendOperationType(req, "query")
		appendStorageTokenId(req, storageTokenId)
		return send(req, "storage")
	end
	
	def updateStorage(storageTokenId, paymentProfile)
		if storageTokenId == nil
			raise InvalidRequest, "storageTokenId is required"
		end
		if paymentProfile == nil
			raise InvalidRequest, "payment profile is required"
		end
		req = Hash::new
		appendHeader(req, "secureStorage")
		appendOperationType(req, "update")
		appendStorageTokenId(req, storageTokenId)
		appendPaymentProfile(req, paymentProfile)
		return send(req, "storage")
	end
	
	def appendAmount(req, amount)
		return appendParam(req, "amount", amount)
	end
	
	def appendApiToken(req, apiToken)
		return appendParam(req, "apiToken", apiToken)
	end
	
	def appendCreditCard(req, creditCard)
		if creditCard != nil
			appendParam(req, "creditCardNumber", creditCard.getCreditCardNumber)
			appendParam(req, "expiryDate", creditCard.getExpiryDate)
			appendParam(req, "cvv2", creditCard.getCvv2)
			appendParam(req, "street", creditCard.getStreet)
			appendParam(req, "zip", creditCard.getZip)
			appendParam(req, "secureCode", creditCard.getSecureCode)
		end
	end
	
	def appendHeader(req, requestCode)
		appendParam(req, "requestCode", requestCode)
		appendMerchantId(req, @merchant.merchantId)
		appendApiToken(req, @merchant.apiToken)
		appendParam(req, "marketSegmentCode", @marketSegment)
	end
	
	def appendOperationType(req, type)
		if type!= nil
			return appendParam(req, "operationCode", type)
		end
	end
	
	def appendPeriodicPurchaseState(req, state)
		if state != nil
			return appendParam(req, "periodicPurchaseStateCode", state)
		end
	end
	
	def appendPeriodicPurchaseSchedule(req, schedule)
		if schedule != nil
			appendParam(req, "periodicPurchaseScheduleTypeCode", schedule.scheduleType)
			appendParam(req, "periodicPurchaseIntervalLength", schedule.intervalLength)
		end
	end
	
	def appendPeriodicPurchaseTransactionId (req, periodicTransactionId)
		appendParam(req, "periodicTransactionId", periodicTransactionId)
	end
	
	def appendPeriodicPurchaseInfo (req, periodicPurchaseInfo)
		appendPeriodicPurchaseTransactionId(req, periodicPurchaseInfo.periodicTransactionId)
		if periodicPurchaseInfo.perPaymentAmount != nil
			appendAmount(req, periodicPurchaseInfo.perPaymentAmount)
		end
		
		if periodicPurchaseInfo.state !=nil
			appendPeriodicPurchaseState(req, periodicPurchaseInfo.state)
		end
		
		if periodicPurchaseInfo.schedule !=nil
			appendPeriodicPurchaseSchedule(req, periodicPurchaseInfo.schedule)
		end
		
		if periodicPurchaseInfo.orderId !=nil
			appendOrderId(req, periodicPurchaseInfo.orderId)
		end
		
		if periodicPurchaseInfo.customerId !=nil
			appendParam(req, "customerId", periodicPurchaseInfo.customerId)
		end
		
		if periodicPurchaseInfo.startDate !=nil
			appendStartDate(req, periodicPurchaseInfo.startDate)
		end
		
		if periodicPurchaseInfo.endDate != nil
			appendEndDate(req, periodicPurchaseInfo.endDate)
		end
		
		if periodicPurchaseInfo.nextPaymentDate !=nil
			appendParam(req, "nextPaymentDate" , periodicPurchaseInfo.nextPaymentDate)
		end
	end
	
	def appendMerchantId(req, merchantId)
		if merchantId.kind_of? String
			appendParam(req, "merchantId", merchantId.to_i)
		else
			appendParam(req, "merchantId", merchantId)
		end
	end
	
	def appendOrderId(req, orderId)
		return appendParam(req, "orderId", orderId)
	end
	
	def appendParam(req, name, value)
		if name.nil?
			return
		end
		
		if !value.nil?
			req[name] = value
		end
	end
	
	def appendTransactionId(req, transactionId)
		return appendParam(req, "transactionId", transactionId)
	end
	
	def appendTransactionOrderId(req, transactionOrderId)
		return appendParam(req, "transactionOrderId", transactionOrderId)
	end
	
	def appendVerificationRequest(req, vr)
		if vr != nil
			appendParam(req, "avsRequestCode", vr.getAvsRequest)
			appendParam(req, "cvv2RequestCode", vr.getCvv2Request)
		end
	end
	
	def appendStorageTokenId(req, storageTokenId)
		return appendParam(req, "storageTokenId", storageTokenId)
	end
	
	def appendTotalNumberInstallments(req, totalNumberInstallments)
		return appendParam(req, "totalNumberInstallments", totalNumberInstallments)
	end
	
	def appendStartDate(req, startDate)
		if startDate != nil
			return appendParam(req, "startDate", startDate)
		end
	end
	
	def appendEndDate(req, endDate)
		if endDate != nil
			return appendParam(req, "endDate", endDate)
		end
	end
	
	def appendPaymentProfiles(req, paymentProfile)
		if paymentProfile == nil
			return
		else
			if paymentProfile.getCreditCard != nil
				appendCreditCard(req, paymentProfile.getCreditCard)
			end
			if paymentProfile.getCustomerProfile != nil
				appendParam(req, "profileLegalName", paymentProfile.getCustomerProfile.legalName)
				appendParam(req, "profileTradeName", paymentProfile.getCustomerProfile.tradeName)
				appendParam(req, "profileWebsite", paymentProfile.getCustomerProfile.website)
				appendParam(req, "profileFirstName", paymentProfile.getCustomerProfile.firstName)
				appendParam(req, "profileLastName", paymentProfile.getCustomerProfile.lastName)
				appendParam(req, "profilePhoneNumber", paymentProfile.getCustomerProfile.phoneNumber)
				appendParam(req, "profileFaxNumber", paymentProfile.getCustomerProfile.faxNumber)
				appendParam(req, "profileAddress1", paymentProfile.getCustomerProfile.address1)
				appendParam(req, "profileAddress2", paymentProfile.getCustomerProfile.address2)
				appendParam(req, "profileCity", paymentProfile.getCustomerProfile.city)
				appendParam(req, "profileProvince", paymentProfile.getCustomerProfile.province)
				appendParam(req, "profilePostal", paymentProfile.getCustomerProfile.postal)
				appendParam(req, "profileCountry", paymentProfile.getCustomerProfile.country)
			end
		end
	end
	
	def send(request, receiptType)
		if (request == nil && receiptType == "creditcard")
			raise InvalidRequest, "a request string is required 25"
		end		
		if (request == nil && receiptType == "storage")
			raise InvalidRequest, "a request string is required"
		end
		
		queryPairs = Array.new
		
		request.each{|key, value| queryPairs<< CGI::escape("#{key}")+"="+CGI::escape("#{value}")}
		query = queryPairs.join("&")
		
		receipt = nil
		response = nil
		
		url = URI.parse(@url)
		server = url.host
		path = url.path
		
		begin
			http = Net::HTTP.new(server, 443)
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			headers = {'Content-Type'=>'application/x-www-form-urlencoded'}
			response, data = http.post(path, query, headers)
		rescue
			@errorMsg = "error attempting to send POST data"
			@errorCode = $REQ_POST_ERROR
			return nil
		end
		begin
			case response
			when Net::HTTPSuccess
				if receiptType =="creditcard"
					receipt = CreditCardReceipt.new(response.body)
				end
				if receiptType == "storage"
					receipt = StorageReceipt.new(response.body)
				end
			else
				@errorMsg = "HTTP error code attempting to send POST request: #{response.code}"
				@errorCode = $REQ_POST_ERROR
			end
		rescue
			@errorMsg = "Could not parse response from the CreditCard gateway"
			@errorCode = $REQ_RESPONSE_ERROR
			return nil
		end
		return receipt
	end
end