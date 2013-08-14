require 'time'

$REQ_MALFORMED_RUL = -1
$REQ_POST_ERROR = -2
$REQ_RESPONSE_ERROR = -4
$REQ_CONNECTION_FAILED = -5
$REQ_INVALID_REQUEST = -6

$MARKET_SEGMENT_INTERNET = "I"
$MARKET_SEGMENT_MOTO = "M"
$MARKET_SEGMENT_RETAIL = "G"

$AVS_VERIFY_STREET_AND_ZIP = 0
$AVS_VERIFY_ZIP_ONLY = 1

$CVV2_NOT_SUBMITTED = 0
$CVV2_PRESENT = 1
$CVV2_PRESENT_BUT_ILLEGIBLE = 2
$CVV2_HAS_NO_CVV2 = 9

$MONTH = 0
$WEEK = 1
$DAY = 2

$NEW = 0
$IN_PROGRESS = 1
$COMPLETE = 2
$ON_HOLD = 3
$CANCELLED = 4

$DATE_FORMAT = "yymmdd"

class ApprovalInfo 
	attr_reader :getAuthorizedAmount, :getApprovalCode, :getTraceNumber, :getReferenceNumber

	def initialize(authorizedAmount, approvalCode, traceNumber, referenceNumber)
		@getAuthorizedAmount = authorizedAmount
		@getApprovalCode = approvalCode
		@getTraceNumber = traceNumber
		@getReferenceNumber = referenceNumber
	end
end

class AvsResponse
	attr_reader :avsResponseCode, :avsErrorCode, :avsErrorMessage, :zipType, :streetMatched
	attr_reader :zipMatched
  
	def initialize(avsResponseCode, streetMatched, zipMatched, zipType, avsErrorCode, avsErrorMessage)
		@avsResponseCode = avsResponseCode
		@streetMatched = streetMatched
		@zipMatched = zipMatched
		@zipType = zipType
		@avsErrorCode = avsErrorCode
		@avsErrorMessage = avsErrorMessage
	end
	
	def isStreetFormatValid
		@streetMatched !=nil ? (true):(false)
	end
	
	def isStreetFormatValidAndMatched
		(isStreetFormatValid == true && @streetMatched ==true) ? (true):(false)
	end
	
	def isZipFormatValid
		@zipMatched != nil ? (true):(false)
	end
	
	def isZipFormatValidAndMatched
		(isZipFormatValid == true && @zipMatched == true) ? (true):(false)
	end

end

class AvsRequest
	attr_reader :code	
	def initialize(code)
		@code = code
	end
end

class CreditCard
	attr_writer :creditCardNumber,	:expiryDate,	:cvv2,	:street
	attr_writer	:zip,				:secureCode
	
	attr_reader :getCreditCardNumber,	:getExpiryDate,	:getCvv2
	attr_reader :getStreet,				:getSecureCode, :getZip
 
	def initialize(creditCardNumber, expiryDate, cvv2, street, zip, secureCode=nil, magneticData = nil)
		@creditCardNumber = creditCardNumber
		@expiryDate = expiryDate
		@cvv2 = cvv2
		@street = street
		@zip = zip
		@secureCode = secureCode
		
		@getCreditCardNumber = @creditCardNumber
		@getExpiryDate = @expiryDate
		@getCvv2 = @cvv2
		@getZip = @zip
		@getStreet = @street
		@getSecureCode = @secureCode
	end
end

class CreditCardReceipt
	attr_accessor	:errorCode,			:errorMessage,			:debugMessage,		:processedDateTime
	
	attr_reader		:isApproved,		:getErrorCode,			:getDebugMessage
	attr_reader		:getErrorMessage,	:getApprovalInfo,		:getAvsResponse
	attr_reader		:getCvv2Response,	:getOrderId,			:getProcessedDateTime	
	attr_reader		:getTransactionId,	:getPeriodicPurchaseInfo
	
	def initialize(response)  
		@params = nil
		@approved = false
		@transactionId = nil
		@orderId = nil
		@processedDateTime = nil #as a Time Object
		@processedDateTimestamp = nil #as a string (can apply your own format)
		@errorCode = nil
		@errorMessage = nil
		@debugMessage = nil
		@approvalInfo = nil
		@avsResponse = nil
		@cvv2Response = nil
		@response = nil
		@periodicPurchaseInfo = nil

		if response == nil
			return
		end
    
		@response = response
		lines = @response.split("\n")
		@params = Hash::new
      
		lines.each do |value|
			paramKey, paramValue = value.split('=')
			@params[paramKey] = paramValue
		end
		
		#parse the param into data class objects
		@approved = @params["APPROVED"] == "true"
		@transactionId = @params["TRANSACTION_ID"]
		@orderId = @params["ORDER_ID"]
		processedDate = @params["PROCESSED_DATE"]
		processedTime = @params["PROCESSED_TIME"]
      
		if (processedDate != nil && processedTime != nil)
			year = processedDate.slice(0,2)
			month = processedDate.slice(2,2)
			day = processedDate.slice(4,2)
			hour = processedTime.slice(0,2)
			minute = processedTime.slice(2,2)
			second = processedTime.slice(4,2)
			
			@processedDateTimestamp = year+"-"+month+"-"+day+" "+hour+":"+minute+":"+second
			@processedDateTime = Time.parse(@processedDateTimestamp)
		   
		else
			@processedDateTime = nil
		end
	
		@errorCode = @params["ERROR_CODE"]
		@errorMessage = @params["ERROR_MESSAGE"]
		@debugMessage = @params["DEBUG_MESSAGE"]
		
		#parse Approval Info
		if(@approved)
			@approvalInfo = ApprovalInfo.new(
			@params["AUTHORIZED_AMOUNT"], 
			@params["APPROVAL_CODE"], 
			@params["TRACE_NUMBER"], 
			@params["REFERENCE_NUMBER"])
		else
			@approvalInfo = nil
		end
		
		#parse AVS Response
        avsResponseAvailable = @params["AVS_RESPONSE_AVAILABLE"]
        if (avsResponseAvailable != nil && avsResponseAvailable)
			@avsResponse = AvsResponse.new(
			@params["AVS_RESPONSE_CODE"], 
			@params["STREET_MATCHED"], 
			@params["ZIP_MATCHED"], 
			@params["ZIP_TYPE"], 
			@params["AVS_ERROR_CODE"], 
			@params["AVS_ERROR_MESSAGE"])
        else
			@avsResponse = nil
        end
		
		#parse Cvv2 Response
        cvv2ResponseAvailable = @params["CVV2_RESPONSE_AVAILABLE"]
        if (cvv2ResponseAvailable != nil && cvv2ResponseAvailable)
			@cvv2Response = Cvv2Response.new(
			@params["CVV2_RESPONSE_CODE"], 
			@params["CVV2_RESPONSE_MESSAGE"])
        else
			@cvv2Response = nil
        end
		
		#parse Periodic Purchase Info
        periodicPurchaseId = @params["PERIODIC_TRANSACTION_ID"]
        if (periodicPurchaseId != nil)
			periodicPurchaseState = @params["PERIODIC_TRANSACTION_STATE"]
			periodicNextPaymentDate = @params["PERIODIC_NEXT_PAYMENT_DATE"]
			periodicLastPaymentId = @params["PERIODIC_LAST_PAYMENT_ID"]
			@periodicPurchaseInfo = PeriodicPurchaseInfo.new(periodicPurchaseId, periodicPurchaseState, nil, nil, nil,nil,nil,nil,periodicNextPaymentDate, periodicLastPaymentId.to_s)
			#periodicTransactionId, :state, :schedule, :perPaymentAmount, :orderId, :customerId, :startDate, :endDate, :nextPaymentDate
        else
			@periodicPurchaseInfo = nil
        end

		#set writer attributes:
		@isApproved = @approved
		@getErrorCode = @errorCode
		@getDebugMessage = @debugMessage
		@getErrorMessage = @errorMessage
		@getApprovalInfo = @approvalInfo
		@getAvsResponse = @avsResponse
		@getCvv2Response = @cvv2Response
		@getOrderId = @orderId
		@getProcessedDateTime = @processedDateTime
		@getTransactionId = @transactionId
		@getPeriodicPurchaseInfo = @periodicPurchaseInfo
	end      
        
    def errorOnlyReceipt(errorCode, errorMessage = nil, debugMessage = nil)
        theReceipt = CreditCardReceipt.new("")
		theReceipt.errorCode = errorCode
		theReceipt.errorMessage = errorMessage
		theReceipt.debugMessage = debugMessage
		theReceipt.processedDateTime = Time.now
		return theReceipt
    end
end
      
class Cvv2Response
	attr_reader :getCode,	:getMessage
	
	def initialize(code, message)
		@code = code
		@message = message
		
		@getCode = @code
		@getMessage = @message
	end
end

class VerificationRequest
	attr_reader :getAvsRequest, :getCvv2Request
	
	def initialize(avsRequest, cvv2Request)
		@avsRequest = avsRequest
		@cvv2Request = cvv2Request
		
		@getAvsRequest = @avsRequest
		@getCvv2Request = @cvv2Request
	end
end

class CustomerProfile
	attr_accessor :legalName,		:tradeName,		:website,		:firstName
	attr_accessor :lastName,		:phoneNumber,	:faxNumber,		:address1
	attr_accessor :address2,		:city,			:province,		:postal
	attr_accessor :country
	
	def initialize()
		@legalName = nil
		@tradeName = nil
		@website = nil
		@firstName = nil
		@lastName = nil
		@phoneNumber = nil
		@faxNumber = nil
		@address1 = nil
		@address2 = nil
		@city = nil
		@province = nil
		@postal = nil
		@country = nil
	end
	
	def isBlank()
		con1 = @firstName !=nil && !@firstName.empty?
		con2 = @lastName != nil && !@lastName.empty?
		con3 = @legalName !=nil && !@legalName.empty?
		con4 = @tradeName != nil && !@tradeName.empty?
		con5 = @address1 != nil && !@address1.empty?
		con6 = @address2 != nil && !@address2.empty?
		con7 = @city != nil && !@city.empty?
		con8 = @province != nil && !@province.empty?
		con9 = @postal != nil && !@postal.empty?
		con10 = @country != nil && !@country.empty?
		con11 = @website != nil && !@website.empty?
		con12 = @phoneNumber != nil && !@phoneNumber.empty?
		con13 = @faxNumber != nil && !@faxNumber.empty?
		return !(con1||con2||con3||con4||con5||con6||con7||con8||con9||con10||con11|con12||con13)
	end
end

class Merchant
	attr_accessor :merchantId, :apiToken, :storeId
	
	def initialize(*args)
		if args.size == 2
			# Merchant(merchantId, apiToken)
			@merchantId = args[0]
			@apiToken = args[1]
		else
			# Merchant(merchantId, apiToken, storeId)
			@merchantId = args[0]
			@apiToken = args[1]
			@storeId = args[2]
		end
	end
end

class StorageReceipt
	attr_accessor :errorCode, :errorMessage, :debugMessage, :processedDateTime
	
	attr_reader :getPaymentProfile,		:getStorageTokenId,		:getDebugMessage
	attr_reader :getErrorCode,			:getErrorMessage,		:getOrderId
	attr_reader :getProcessedDateTime,	:getTransactionId,		:isApproved
	
	def initialize(response)
		@params = nil
		@approved = false
		@transactionId = nil
		@orderId = nil
		@processedDateTime = nil
		@errorCode = nil
		@errorMessage = nil
		@debugMessage = nil
		@response = nil
		@paymentProfile = nil
		@storageTokenId = nil
		
		if response == nil
		  return
		end
    
		@response = response
		lines = @response.split("\n")
		@params = Hash::new
    
		lines.each do |value|
		  paramKey, paramValue = value.split("=")
		  @params[paramKey] = paramValue
		end
    
		@approved = @params["APPROVED"] == "true"
		@storageTokenId = @params["STORAGE_TOKEN_ID"]
		@errorCode = @params["ERROR_CODE"]
		@errorMessage = @params["ERROR_MESSAGE"]
		@debugMessage = @params["DEBUG_MESSAGE"]
    
		paymentProfileAvailable = @params["PAYMENT_PROFILE_AVAILABLE"]
    
		processedDate = @params["PROCESSED_DATE"]
		processedTime = @params["PROCESSED_TIME"]
      
		if (processedDate != nil && processedTime != nil)
			year = processedDate.slice(0,2)
			month = processedDate.slice(2,2)
			day = processedDate.slice(4,2)
			hour = processedTime.slice(0,2)
			minute = processedTime.slice(2,2)
			second = processedTime.slice(4,2)
			time = year+"-"+month+"-"+day+" "+hour+":"+minute+":"+second
			@processedDateTime = Time.parse(time)
		else
			@processedDateTime = nil
		end	
	
		if (paymentProfileAvailable != nil && paymentProfileAvailable)		  
			creditCard = nil
			creditCardAvailable = @params["CREDIT_CARD_AVAILABLE"]
		  
			if (creditCardAvailable != nil && creditCardAvailable)
				sanitized = @params["CREDIT_CARD_NUMBER"]
				sanitized = sanitized.gsub("\\*", "")
				creditCard = CreditCard.new(sanitized, @params["EXPIRY_DATE"])
			end
		  
			profile = nil
			customerProfileAvailable = @params["CUSTOMER_PROFILE_AVAILABLE"]
			
			if (customerProfileAvailable != nil && customerProfileAvailable)
				profile = CustomerProfile.new()
				profile.setLegalName(@params["CUSTOMER_PROFILE_LEGAL_NAME"])
				profile.setTradeName(@params["CUSTOMER_PROFILE_TRADE_NAME"])
				profile.setWebsite(@params["CUSTOMER_PROFILE_WEBSITE"])
				profile.setFirstName(@params["CUSTOMER_PROFILE_FIRST_NAME"])
				profile.setLastName(@params["CUSTOMER_PROFILE_LAST_NAME"])
				profile.setPhoneNumber(@params["CUSTOMER_PROFILE_PHONE_NUMBER"])
				profile.setFaxNumber(@params["CUSTOMER_PROFILE_FAX_NUMBER"])
				profile.setAddress1(@params["CUSTOMER_PROFILE_ADDRESS1"])
				profile.setAddress2(@params["CUSTOMER_PROFILE_ADDRESS2"])
				profile.setCity(@params["CUSTOMER_PROFILE_CITY"])
				profile.setProvince(@params["CUSTOMER_PROFILE_PROVINCE"])
				profile.setPostal(@params["CUSTOMER_PROFILE_COUNTRY"])
			end
			
			@paymentProfile = PaymentProfile.new(creditCard, profile)
		else
			@paymentProfile = nil
		end		
		#read methods:
		@getPaymentProfile = @paymentProfile
		@getStorageTokenId = @storageTokenId
		@getDebugMessage = @debugMessage
		@getErrorCode = @errorCode
		@getErrorMessage = @errorMessage
		@getOrderId = @orderId
		@getProcessedDateTime = @processedDateTime
		@getTransactionId = @transactionId
		@isApproved = @approved
	end
	
	def errorOnlyReceipt(errorCode, errorMessage = nil, debugMessage = nil)
		theReceipt = Hash::new
		theReceipt["errorCode"] = errorCode
		theReceipt["errorMsg"] = errorMessage
		theReceipt["debugMsg"] = debugMessage
		theReceipt["processedDateTime"] = Time.now
		return theReceipt
	end 
end

class Schedule
	attr_accessor :scheduleType, :intervalLength
	
	def initialize(type, intervalLength)
		@scheduleType = type
		@intervalLength = intervalLength
	end

end

class PaymentProfile
	attr_reader :getCreditCard, :getCustomerProfile
	
	def initialize(creditCard, customerProfile)
		@creditCard = creditCard
		@customerProfile = customerProfile
		
		@getCreditCard = @creditCard
		@getCustomerProfile = @customerProfile
	end
	
	def setCreditCard(newCreditCard)
		@creditCard = newCreditCard
	end
	
	def setCustomerProfile(newCustomerProfile)
		@customerProfile = newCustomerProfile
	end
end

class PeriodicPurchaseInfo
	attr_reader :periodicTransactionId, :state, :schedule, :perPaymentAmount, :orderId, :customerId, :startDate, :endDate, :nextPaymentDate, :lastPaymentId
	
	def initialize(periodicTransactionId, state, schedule, perPaymentAmount =nil, orderId =nil, customerId =nil, startDate =nil, endDate =nil, nextPaymentDate = nil, lastPaymentId = nil)
		@periodicTransactionId = periodicTransactionId
		@state = state
		@schedule = schedule
		@startDate = startDate
		@endDate = endDate
		@perPaymentAmount = perPaymentAmount
		@orderId = orderId
		@customerId = customerId
		@nextPaymentDate = nextPaymentDate
		@lastPaymentId = lastPaymentId
	end
end

class InvalidRequest < StandardError
end