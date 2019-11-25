use CDS_Send
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[send_GetFieldData]
as

declare @send_status_PENDING int = (select send_status_id from send_status where code = 'PENDING')


select 'account_send' [table_name], acs.account_send_id [primary_key], acs.html_template_version_id, acs.language_id,
	a.account_name [ACCOUNT_NAME],
	a.account_num [ACCOUNT_NUM],
	a.[address] [ADDRESS],
	null [BACK_IMAGE_FORMAT],
	null [BANK_ACCOUNT],
	null [BANK_TRANSACTION_AMOUNT],
	null [BANK_TRANSACTION_DUE_DATE],
	null [BIRTH_CITY],
	bc.[name] [BIRTH_COUNTRY],
	cu.birth_date [BIRTH_DATE],
	null [BIRTH_STATE],
	a.business_tax_num [BUSINESS_TAX_NUM],
	null [CALCULATED_ACTIVATION_DATE],
	null [CITIZENSHIP_COUNTRY],
	a.city [CITY],
	c.[name] [COMMODITY],
	null [COMPANY_NAME],
	c2.[name] [COUNTRY],
	null [CSR_NAME],
	null [CSR_NUM],
	cu.cust_name [CUST_NAME],
	null [EMAIL_ADDRESS],
	null [EMAIL1],
	null [ESCO],
	null [EXPIRATION_DATE],
	f.[name] [FACILITY],
	co.first_name [FIRST_NAME],
	null [FRONT_IMAGE_FORMAT],
	gut.[name] [GAS_USE_TYPE],
	null [GOVERNMENT_ID_CARD_BACK],
	null [GOVERNMENT_ID_CARD_FRONT],
	null [IMAGE_TYPE],
	null [INVITEE_FIRST_NAME],
	null [INVITEE_NOTE],
	null [INVOICE_URL],
	null [LAND_PHONE],
	co.last_name [LAST_NAME],
	null [MARITAL_STATUS],
	a.meter_num [METER_NUM],
	null [ORDER_DATE],
	a.personal_tax_num [PERSONAL_TAX_NUM],
	null [PHONE_MOBILE],
	null [PHONE1],
	null [PHONE1_EXT],
	null [PHOTO],
	s.[name] [STATE],
	null [STATE_CODE],
	null [STREET_NAME],
	a.street_num [STREET_NUM],
	a.street_part [STREET_PART],
	a.suspension_date [ACCOUNT_SUSPENSION_DATE],
	a.tax_rate [TAX_RATE],
	null [TITLE],
	null [TO_EMAIL],
	ht.[url] + cs.web_reg_key [URL],
	a.zip [ZIP]
from account_send acs
join cds.dbo.html_template_version htv on acs.html_template_version_id = htv.html_template_version_id
join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
left join cust_send cs on acs.cust_send_id = cs.cust_send_id
left join cds.dbo.cust cu on cs.cust_id = cu.cust_id
left join cds.dbo.country bc on cu.birth_country_id = bc.country_id
join cds.dbo.account a on acs.account_id = a.account_id
left join cds.dbo.commodity c on a.commodity_id = c.commodity_id
left join cds.dbo.facility f on a.facility_id = f.facility_id
left join cds.dbo.[state] s on a.state_id = s.state_id
left join cds.dbo.country c2 on a.country_id = c2.country_id
left join cds.dbo.gas_use_type gut on a.gas_use_type_id = gut.gas_use_type_id
left join
	(select c.*
	from cds.dbo.contact c
	join cds.dbo.contact_type ct on c.contact_type_id = ct.contact_type_id
	where ct.code = 'WL') co on a.cust_id = co.cust_id
where acs.send_status_id = @send_status_PENDING
and htt.code not in ('CERTIFIED_COLLECTIONS_EMAIL','INVOICE','INVOICE_MULTILINE')

union all

select 'csr_send' [table_name], cs.csr_send_id [primary_key], cs.html_template_version_id, cs.language_id,
	null [ACCOUNT_NAME],
	null [ACCOUNT_NUM],
	null [ADDRESS],
	ci.back_format [BACK_IMAGE_FORMAT],
	null [BANK_ACCOUNT],
	null [BANK_TRANSACTION_AMOUNT],
	null [BANK_TRANSACTION_DUE_DATE],
	c.birth_city [BIRTH_CITY],
	bc.[name] [BIRTH_COUNTRY],
	c.birth_date [BIRTH_DATE],
	c.birth_state_code [BIRTH_STATE],
	c.business_tax_num [BUSINESS_TAX_NUM],
	null [CALCULATED_ACTIVATION_DATE],
	cc.[name] [CITIZENSHIP_COUNTRY],
	c.city [CITY],
	null [COMMODITY],
	c.company_name [COMPANY_NAME],
	c2.[name] [COUNTRY],
	null [CSR_NAME],
	c.csr_num [CSR_NUM],
	oc.cust_name [CUST_NAME],
	null [EMAIL_ADDRESS],
	null [EMAIL1],
	null [ESCO],
	ca.end_date [EXPIRATION_DATE],
	null [FACILITY],
	c.first_name [FIRST_NAME],
	ci.front_format [FRONT_IMAGE_FORMAT],
	null [GAS_USE_TYPE],
	ci.back_id [GOVERNMENT_ID_CARD_BACK],
	ci.front_id [GOVERNMENT_ID_CARD_FRONT],
	i.csr_image_type [IMAGE_TYPE],
	cs.invitee_first_name [INVITEE_FIRST_NAME],
	cs.invitee_note [INVITEE_NOTE],
	null [INVOICE_URL],
	c.land_phone [LAND_PHONE],
	c.last_name [LAST_NAME],
	ms.[name] [MARITAL_STATUS],
	null [METER_NUM],
	null [ORDER_DATE],
	c.personal_tax_num [PERSONAL_TAX_NUM],
	c.phone_mobile [PHONE_MOBILE],
	null [PHONE1],
	null [PHONE1_EXT],
	i.photo [PHOTO],
	null [STATE],
	c.state_code [STATE_CODE],
	c.street_name [STREET_NAME],
	c.street_num [STREET_NUM],
	c.street_part [STREET_PART],
	null [ACCOUNT_SUSPENSION_DATE],
	null [TAX_RATE],
	null [TITLE],
	c.email [TO_EMAIL],
	ht.[url] + cs.web_reg_key [URL],
	c.zip [ZIP]
from csr_send cs
join cds.dbo.html_template_version htv on cs.html_template_version_id = htv.html_template_version_id
join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
join cds.dbo.csr c on cs.csr_id = c.csr_id
left join cds.dbo.country bc on c.birth_country_id = bc.country_id
left join cds.dbo.country cc on c.citizenship_country_id = cc.country_id
left join cds.dbo.country c2 on c.country_id = c2.country_id
left join cds.dbo.marital_status ms on c.marital_status_id = ms.marital_status_id
left join
	(select cc.csr_id, max(cc.end_date) [end_date]
	from cds.dbo.csr_card cc
	join cds.dbo.csr_card_status ccs on cc.csr_card_status_id = ccs.csr_card_status_id
	where ccs.code <> 'INACTIVE'
	group by cc.csr_id) ca on cs.csr_id = ca.csr_id
left join
	(select cc.csr_card_id, ci.photo, cit.code [csr_image_type]
	from cds.dbo.csr_card cc
	join cds.dbo.csr_image ci on cc.csr_image_id = ci.csr_image_id
	join cds.dbo.csr_image_type cit on ci.csr_image_type_id = cit.csr_image_type_id) i on cs.csr_card_id = i.csr_card_id
left join cds.dbo.ord_cust oc on cs.ord_cust_id = oc.ord_cust_id
left join
	(select fb.csr_id, fb.back_id, fb.front_id, b.image_format [back_format], f.image_format [front_format]
	from
		(select ci.csr_id, 
			max(case when cit.code = 'GOVERNMENT_ID_CARD_BACK' then ci.csr_image_id end) [back_id], 
			max(case when cit.code = 'GOVERNMENT_ID_CARD_FRONT' then ci.csr_image_id end) [front_id]
		from cds.dbo.csr_image ci
		join cds.dbo.csr_image_type cit on ci.csr_image_type_id = cit.csr_image_type_id
		group by ci.csr_id) fb
	left join cds.dbo.csr_image b on fb.back_id = b.csr_image_id
	left join cds.dbo.csr_image f on fb.front_id = f.csr_image_id) ci on cs.csr_id = ci.csr_id
where cs.send_status_id = @send_status_PENDING
and htt.code not in ('ASSOCIATE_RECEIPT')

union all

select 'cust_send' [table_name], cs.cust_send_id [primary_key], cs.html_template_version_id, cs.language_id,
	c.cust_name [ACCOUNT_NAME],
	null [ACCOUNT_NUM],
	c.[address] [ADDRESS],
	null [BACK_IMAGE_FORMAT],
	isnull(bc.bank_account,bt.bank_account) [BANK_ACCOUNT],
	bt.tran_amount [BANK_TRANSACTION_AMOUNT],
	dateadd(day,3,cast(getdate() as date)) [BANK_TRANSACTION_DUE_DATE],
	null [BIRTH_CITY],
	bc.[name] [BIRTH_COUNTRY],
	c.birth_date [BIRTH_DATE],
	null [BIRTH_STATE],
	a.business_tax_num [BUSINESS_TAX_NUM],
	null [CALCULATED_ACTIVATION_DATE],
	null [CITIZENSHIP_COUNTRY],
	c.city [CITY],
	null [COMMODITY],
	null [COMPANY_NAME],
	c2.[name] [COUNTRY],
	null [CSR_NAME],
	null [CSR_NUM],
	c.cust_name [CUST_NAME],
	null [EMAIL_ADDRESS],
	co.email1 [EMAIL1],
	e.[name] [ESCO],
	null [EXPIRATION_DATE],
	null [FACILITY],
	co.first_name [FIRST_NAME],
	null [FRONT_IMAGE_FORMAT],
	null [GAS_USE_TYPE],
	null [GOVERNMENT_ID_CARD_BACK],
	null [GOVERNMENT_ID_CARD_FRONT],
	null [IMAGE_TYPE],
	null [INVITEE_FIRST_NAME],
	null [INVITEE_NOTE],
	null [INVOICE_URL],
	null [LAND_PHONE],
	co.last_name [LAST_NAME],
	null [MARITAL_STATUS],
	null [METER_NUM],
	b.inserted_date [ORDER_DATE],
	a.personal_tax_num [PERSONAL_TAX_NUM],
	null [PHONE_MOBILE],
	co.phone1 [PHONE1],
	co.phone1_ext [PHONE1_EXT],
	null [PHOTO],
	s.[name] [STATE],
	c.state_code [STATE_CODE],
	null [STREET_NAME],
	c.street_num [STREET_NUM],
	c.street_part [STREET_PART],
	null [ACCOUNT_SUSPENSION_DATE],
	null [TAX_RATE],
	co.title [TITLE],
	null [TO_EMAIL],
	ht.[url] + cs.web_reg_key [URL],
	c.zip [ZIP]
from cust_send cs
join cds.dbo.html_template_version htv on cs.html_template_version_id = htv.html_template_version_id
join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
join cds.dbo.cust c on cs.cust_id = c.cust_id
left join cds.dbo.country bc on c.birth_country_id = bc.country_id
left join cds.dbo.[state] s on c.state_id = s.state_id
left join cds.dbo.esco e on c.esco_id = e.esco_id
left join cds.dbo.country c2 on c.country_id = c2.country_id
left join cds.dbo.bank_contract bc on bc.bank_contract_id = cs.bank_contract_id
left join
	(select c.*
	from cds.dbo.contact c
	join cds.dbo.contact_type ct on c.contact_type_id = ct.contact_type_id
	where ct.code = 'WL') co on c.cust_id = co.cust_id
left join cds.dbo.bank b on cs.bank_id = b.bank_id
left join
	(select cust_id, max(personal_tax_num) [personal_tax_num], max(business_tax_num) [business_tax_num]
	from cds.dbo.account
	group by cust_id) a on c.cust_id = a.cust_id
left join
	(select bt.bank_transaction_id, bt.tran_amount, b.bank_account
	from cds.dbo.bank_transaction bt
	join cds.dbo.bank b on bt.bank_id = b.bank_id) bt on cs.bank_transaction_id = bt.bank_transaction_id
where cs.send_status_id = @send_status_PENDING

union all

select 'ord_account_send' [table_name], oas.ord_account_send_id [primary_key], oas.html_template_version_id, oas.language_id,
	oa.account_name [ACCOUNT_NAME],
	isnull(c3.account_num,oa.account_num) [ACCOUNT_NUM],
	oa.[address] [ADDRESS],
	null [BACK_IMAGE_FORMAT],
	isnull(c3.bank_account,oa.bank_account) [BANK_ACCOUNT],
	null [BANK_TRANSACTION_AMOUNT],
	null [BANK_TRANSACTION_DUE_DATE],
	null [BIRTH_CITY],
	bc.[name] [BIRTH_COUNTRY],
	oc.birth_date [BIRTH_DATE],
	null [BIRTH_STATE],
	isnull(c3.business_tax_num,oa.business_tax_num) [BUSINESS_TAX_NUM],
	c3.proposed_flow_date [CALCULATED_ACTIVATION_DATE],
	null [CITIZENSHIP_COUNTRY],
	oa.city [CITY],
	c.[name] [COMMODITY],
	null [COMPANY_NAME],
	c2.[name] [COUNTRY],
	null [CSR_NAME],
	null [CSR_NUM],
	oc.cust_name [CUST_NAME],
	null [EMAIL_ADDRESS],
	oco.email1 [EMAIL1],
	e.[name] [ESCO],
	null [EXPIRATION_DATE],
	f.[name] [FACILITY],
	oco.first_name [FIRST_NAME],
	null [FRONT_IMAGE_FORMAT],
	gut.[name] [GAS_USE_TYPE],
	null [GOVERNMENT_ID_CARD_BACK],
	null [GOVERNMENT_ID_CARD_FRONT],
	null [IMAGE_TYPE],
	null [INVITEE_FIRST_NAME],
	null [INVITEE_NOTE],
	null [INVOICE_URL],
	null [LAND_PHONE],
	oco.last_name [LAST_NAME],
	null [MARITAL_STATUS],
	oa.meter_num [METER_NUM],
	oc.order_date [ORDER_DATE],
	isnull(c3.personal_tax_num,oa.personal_tax_num) [PERSONAL_TAX_NUM],
	null [PHONE_MOBILE],
	case
		when f2.code = 'R' and oco.phone2 is not null then oco.phone2
		when f2.code = 'R' and oco.phone2 is null then oco.cell_phone
		when f2.code = 'C' and oco.phone1 is not null then oco.phone1
		when f2.code = 'C' and oco.phone1 is null and oco.phone2 is not null then oco.phone2
		when f2.code = 'C' and oco.phone1 is null and oco.phone2 is null then oco.cell_phone
	end [PHONE1],
	case
		when f2.code = 'R' and oco.phone2 is not null then oco.phone2_ext
		when f2.code = 'C' and oco.phone1 is not null then oco.phone1_ext
		when f2.code = 'C' and oco.phone1 is null and oco.phone2 is not null then oco.phone2_ext
	end [PHONE1_EXT],
	null [PHOTO],
	s.[name] [STATE],
	null [STATE_CODE],
	null [STREET_NAME],
	oa.street_num [STREET_NUM],
	oa.street_part [STREET_PART],
	null [ACCOUNT_SUSPENSION_DATE],
	oa.tax_rate [TAX_RATE],
	oco.title [TITLE],
	null [TO_EMAIL],
	ht.[url] + ocs.web_reg_key [URL],
	oa.zip [ZIP]
from ord_account_send oas
join cds.dbo.html_template_version htv on oas.html_template_version_id = htv.html_template_version_id
join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
left join cds.dbo.[contract] c3 on oas.contract_id = c3.contract_id
left join ord_cust_send ocs on oas.ord_cust_send_id = ocs.ord_cust_send_id
left join cds.dbo.ord_cust oc on ocs.ord_cust_id = oc.ord_cust_id
left join cds.dbo.country bc on oc.birth_country_id = bc.country_id
left join cds.dbo.facility f2 on oc.facility_id = f2.facility_id
join cds.dbo.ord_account oa on oas.ord_account_id = oa.ord_account_id
left join cds.dbo.commodity c on isnull(c3.commodity_id,oa.commodity_id) = c.commodity_id
left join cds.dbo.facility f on isnull(c3.facility_id,oa.facility_id) = f.facility_id
left join cds.dbo.[state] s on oa.state_id = s.state_id
left join cds.dbo.country c2 on oa.country_id = c2.country_id
left join cds.dbo.esco e on oa.esco_id = e.esco_id
left join
	(select oc.*
	from cds.dbo.ord_contact oc
	join cds.dbo.ord_contact_type oct on oc.ord_contact_type_id = oct.ord_contact_type_id
	where oct.code = 'WL') oco on ocs.ord_cust_id = oco.ord_cust_id
left join cds.dbo.gas_use_type gut on oa.gas_use_type_id = gut.gas_use_type_id
where oas.send_status_id = @send_status_PENDING

union all

select 'ord_cust_send' [table_name], ocs.ord_cust_send_id [primary_key], ocs.html_template_version_id, ocs.language_id,
	null [ACCOUNT_NAME],
	null [ACCOUNT_NUM],
	oc.[address] [ADDRESS],
	null [BACK_IMAGE_FORMAT],
	null [BANK_ACCOUNT],
	null [BANK_TRANSACTION_AMOUNT],
	null [BANK_TRANSACTION_DUE_DATE],
	null [BIRTH_CITY],
	bc.[name] [BIRTH_COUNTRY],
	oc.birth_date [BIRTH_DATE],
	null [BIRTH_STATE],
	null [BUSINESS_TAX_NUM],
	null [CALCULATED_ACTIVATION_DATE],
	null [CITIZENSHIP_COUNTRY],
	oc.city [CITY],
	null [COMMODITY],
	null [COMPANY_NAME],
	c2.[name] [COUNTRY],
	null [CSR_NAME],
	null [CSR_NUM],
	oc.cust_name [CUST_NAME],
	null [EMAIL_ADDRESS],
	oco.email1 [EMAIL1],
	e.[name] [ESCO],
	null [EXPIRATION_DATE],
	null [FACILITY],
	oco.first_name [FIRST_NAME],
	null [FRONT_IMAGE_FORMAT],
	null [GAS_USE_TYPE],
	null [GOVERNMENT_ID_CARD_BACK],
	null [GOVERNMENT_ID_CARD_FRONT],
	null [IMAGE_TYPE],
	null [INVITEE_FIRST_NAME],
	null [INVITEE_NOTE],
	null [INVOICE_URL],
	null [LAND_PHONE],
	oco.last_name [LAST_NAME],
	null [MARITAL_STATUS],
	null [METER_NUM],
	oc.order_date [ORDER_DATE],
	null [PERSONAL_TAX_NUM],
	null [PHONE_MOBILE],
	case
		when f.code = 'R' and oco.phone2 is not null then oco.phone2
		when f.code = 'R' and oco.phone2 is null then oco.cell_phone
		when f.code = 'C' and oco.phone1 is not null then oco.phone1
		when f.code = 'C' and oco.phone1 is null and oco.phone2 is not null then oco.phone2
		when f.code = 'C' and oco.phone1 is null and oco.phone2 is null then oco.cell_phone
	end [PHONE1],
	case
		when f.code = 'R' and oco.phone2 is not null then oco.phone2_ext
		when f.code = 'C' and oco.phone1 is not null then oco.phone1_ext
		when f.code = 'C' and oco.phone1 is null and oco.phone2 is not null then oco.phone2_ext
	end [PHONE1_EXT],
	null [PHOTO],
	s.[name] [STATE],
	oc.state_code [STATE_CODE],
	null [STREET_NAME],
	oc.street_num [STREET_NUM],
	oc.street_part [STREET_PART],
	null [ACCOUNT_SUSPENSION_DATE],
	null [TAX_RATE],
	oco.title [TITLE],
	null [TO_EMAIL],
	ht.[url] + ocs.web_reg_key [URL],
	oc.zip [ZIP]
from ord_cust_send ocs
join cds.dbo.html_template_version htv on ocs.html_template_version_id = htv.html_template_version_id
join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
join cds.dbo.ord_cust oc on ocs.ord_cust_id = oc.ord_cust_id
left join cds.dbo.country bc on oc.birth_country_id = bc.country_id
left join cds.dbo.[state] s on oc.state_id = s.state_id
left join cds.dbo.esco e on oc.esco_id = e.esco_id
left join cds.dbo.country c2 on oc.country_id = c2.country_id
left join cds.dbo.facility f on oc.facility_id = f.facility_id
left join
	(select oc.*
	from cds.dbo.ord_contact oc
	join cds.dbo.ord_contact_type oct on oc.ord_contact_type_id = oct.ord_contact_type_id
	where oct.code = 'WL') oco on oc.ord_cust_id = oco.ord_cust_id
where ocs.send_status_id = @send_status_PENDING
go

