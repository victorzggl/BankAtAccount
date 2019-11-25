
CREATE procedure [dbo].[cds_GetBankForBankMandate]
as

select b.bank_id, b.bank_reg_key, isnull(c1.email1,c2.email) [email], b.bank_account, b.bank_account_key, b.bank_account_name
from bank b
join bank_status bs on b.bank_status_id = bs.bank_status_id
left join
	(select c.cust_id, co.email1
	from cust c
	join contact co on c.cust_id = co.cust_id
	join contact_type ct on co.contact_type_id = ct.contact_type_id
	where ct.code = 'WL') c1 on b.cust_id = c1.cust_id
left join csr c2 on b.csr_id = c2.csr_id
where b.bank_authorization_key is null
and isnull(c1.email1,c2.email) is not null
and (b.error is null
	or b.error like 'System.Net.Http.HttpRequestException: An error occurred while sending the request.%'
	or b.error like 'System.Data.Entity.Core.EntityException: An exception has been raised that is likely due to a transient failure.%')
and bs.code = 'NEW'
order by b.bank_id
go

