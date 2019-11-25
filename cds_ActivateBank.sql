
CREATE procedure [dbo].[cds_ActivateBank] @bank_id int
as

declare @bank_status_INACTIVE int = (select bank_status_id from bank_status where code = 'INACTIVE'),
		@bank_status_ACTIVE int = (select bank_status_id from bank_status where code = 'ACTIVE')

update b2 set bank_status_id = @bank_status_INACTIVE, bank_status_date = getdate()
from bank b
join bank b2 on (b.csr_id = b2.csr_id or b.cust_id = b2.cust_id) and b.bank_id <> b2.bank_id
where b.bank_id = @bank_id
and b2.bank_status_id = @bank_status_ACTIVE

update bank set bank_status_id = @bank_status_ACTIVE, bank_status_date = getdate()
where bank_id = @bank_id
and bank_status_id <> @bank_status_ACTIVE
go

