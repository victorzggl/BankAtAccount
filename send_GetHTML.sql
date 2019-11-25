
CREATE procedure [dbo].[send_GetHTML] @html_type varchar(10), @throttle int = 50, @email_provider varchar(50) = null
as

--exec send_GetHTML @html_type = 'EMAIL'

declare @send_status_HTML_CREATED int = (select send_status_id from send_status where code = 'HTML_CREATED'),
		@html_template_version_part_type_EMAIL_SUBJECT int = (select html_template_version_part_type_id from cds.dbo.html_template_version_part_type where code = 'EMAIL_SUBJECT'),
		@email_provider_id int

if @throttle is null
	set @throttle = 50

select @email_provider_id = email_provider_id, @throttle = throttle
from cds.dbo.email_provider
where code = @email_provider

select top(@throttle) s.table_name, s.primary_key, s.html, s.from_email, s.to_email
, replace(replace(replace(replace(htvpl.part_text
,'{{FIRST_NAME}}',isnull(s.first_name,'')),
	'{{LAST_NAME}}',isnull(s.last_name,''))
		,'{{Account_Num}}',isnull(s.account_num,''))
			,'{{Tracking_ID}}',isnull(s.account_action_id,''))
			[email_subject],
	s.cds_key, s.pdf_path, htt.file_path + s.[file_name] [file_path], s.cc_email, et.code [email_type],
	s.from_phone, s.to_phone, s.from_phone_user, s.from_phone_password
from
	(select 'account_send' [table_name], s.account_send_id [primary_key], s.html_template_version_id, s.html, s2.from_email [from_email], s2.to_email [to_email], s.language_id, co.first_name [first_name], co.last_name [last_name],
		s.account_id [cds_key], s.pdf_path,
		case
			when s.account_invoice_id is not null then concat('IGL_',year(ai.[start_date]),'_',right('0' + cast(month(ai.[start_date]) as varchar(2)),2),'_',ai.account_num,'_',s.account_send_id,'.pdf')
			else concat('account_send.',s.account_send_id,'.account.',s.account_id,'.pdf')
		end [file_name], null [cc_email], s.account_action_id, a.account_num,
		null [from_phone], null [to_phone], null [from_phone_user], null [from_phone_password]
	from account_send s
	join cds.dbo.account a on s.account_id = a.account_id
	left join cust_send s2 on s.cust_send_id = s2.cust_send_id
	left join
		(select c.*
		from cds.dbo.contact c
		join cds.dbo.contact_type ct on c.contact_type_id = ct.contact_type_id
		where ct.code = 'WL') co on a.cust_id = co.cust_id
	left join cds.dbo.account_invoice ai on s.account_invoice_id = ai.account_invoice_id
	where s.send_status_id = @send_status_HTML_CREATED

	union all

	select 'csr_send' [table_name], s.csr_send_id [primary_key], s.html_template_version_id, s.html, s.from_email, s.to_email, s.language_id, c.first_name, c.last_name,
		s.csr_id [cds_key],
		s.pdf_path,
		case
			when htt.code = 'ASSOCIATE_GOV_ID_PEC_ATTACHMENT' then concat('csr_send.',s.csr_send_id,'.csr.',s.csr_id,'.tiff')
			else concat('csr_send.',s.csr_send_id,'.csr.',s.csr_id,'.pdf')
		end [file_name], s.cc_email, null [account_action_id], null [account_num],
		s.from_phone, s.to_phone, scp.[user] [from_phone_user], scp.[password] [from_phone_password]
	from csr_send s
	join cds.dbo.csr c on s.csr_id = c.csr_id
	join cds.dbo.html_template_version htv on s.html_template_version_id = htv.html_template_version_id
	join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
	join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
	left join cds.dbo.sales_corp_phone scp on ht.sales_corp_id = scp.sales_corp_id and ht.phone_type_id = scp.phone_type_id
	where s.send_status_id = @send_status_HTML_CREATED

	union all

	select 'cust_send' [table_name], s.cust_send_id [primary_key], s.html_template_version_id, s.html, s.from_email, s.to_email, s.language_id, co.first_name, co.last_name,
		s.cust_id [cds_key], s.pdf_path,
		case
			when htt.code = 'GREEN_CERTIFICATE' then concat(replace(replace(replace(c.cust_name,' ','_'),'?',''),'/',''),'.',s.cust_send_id,'.pdf')
			else concat('cust_send.',s.cust_send_id,'.cust.',s.cust_id,'.pdf')
		end [file_name], null [cc_email], null [account_action_id], null [account_num],
		s.from_phone, s.to_phone, ep.[user] [from_phone_user], ep.[password] [from_phone_password]
	from cust_send s
	join cds.dbo.cust c on s.cust_id = c.cust_id
	join cds.dbo.html_template_version htv on s.html_template_version_id = htv.html_template_version_id
	join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
	join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
	left join cds.dbo.esco_phone ep on ht.esco_id = ep.esco_id and ht.phone_type_id = ep.phone_type_id
	left join
		(select c.*
		from cds.dbo.contact c
		join cds.dbo.contact_type ct on c.contact_type_id = ct.contact_type_id
		where ct.code = 'WL') co on s.cust_id = co.cust_id
	where s.send_status_id = @send_status_HTML_CREATED

	union all

	select 'ord_account_send' [table_name], s.ord_account_send_id [primary_key], s.html_template_version_id, s.html, null [from_email], null [to_email], s.language_id, oco.first_name, oco.last_name,
		s.ord_account_id [cds_key], s.pdf_path, concat('ord_account_send.',s.ord_account_send_id,'.ord_account.',s.ord_account_id,'.pdf') [file_name], null [cc_email], null [account_action_id], null [account_num],
		null [from_phone], null [to_phone], null [from_phone_user], null [from_phone_password]
	from ord_account_send s
	join cds.dbo.ord_account oa on s.ord_account_id = oa.ord_account_id
	left join
		(select oc.*
		from cds.dbo.ord_contact oc
		join cds.dbo.ord_contact_type oct on oc.ord_contact_type_id = oct.ord_contact_type_id
		where oct.code = 'WL') oco on oa.ord_cust_id = oco.ord_cust_id
	where s.send_status_id = @send_status_HTML_CREATED

	union all

	select 'ord_cust_send' [table_name], s.ord_cust_send_id [primary_key], s.html_template_version_id, s.html, s.from_email, s.to_email, s.language_id, oco.first_name, oco.last_name,
		s.ord_cust_id [cds_key], s.pdf_path, concat('ord_cust_send.',s.ord_cust_send_id,'.ord_cust.',s.ord_cust_id,'.pdf') [file_name], s.cc_email, null [account_action_id], null [account_num],
		s.from_phone, s.to_phone, scp.[user] [from_phone_user], scp.[password] [from_phone_password]
	from ord_cust_send s
	join cds.dbo.html_template_version htv on s.html_template_version_id = htv.html_template_version_id
	join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
	left join cds.dbo.sales_corp_phone scp on ht.sales_corp_id = scp.sales_corp_id and ht.phone_type_id = scp.phone_type_id
	left join
		(select oc.*
		from cds.dbo.ord_contact oc
		join cds.dbo.ord_contact_type oct on oc.ord_contact_type_id = oct.ord_contact_type_id
		where oct.code = 'WL') oco on s.ord_cust_id = oco.ord_cust_id
	where s.send_status_id = @send_status_HTML_CREATED) s
join cds.dbo.html_template_version htv on s.html_template_version_id = htv.html_template_version_id
join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
left join cds.dbo.html_template_version_part htvp on s.html_template_version_id = htvp.html_template_version_id and htvp.html_template_version_part_type_id = @html_template_version_part_type_EMAIL_SUBJECT
left join cds.dbo.html_template_version_part_language htvpl on htvp.html_template_version_part_id = htvpl.html_template_version_part_id and s.language_id = htvpl.language_id
left join cds.dbo.email_type et on ht.email_type_id = et.email_type_id
where (ht.email_provider_id = @email_provider_id or @email_provider_id is null)
and ((@html_type = 'PDF' and htt.create_pdf_flag = 1)
	or (@html_type = 'EMAIL' and htt.send_email_flag = 1)
	or (@html_type = 'EXTRACT' and htt.extract_pdf_pages_flag = 1)
	or (@html_type = 'TEXT' and htt.send_text_flag = 1))
go

