use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[cds_InsertInvoicePayments]
as

declare @days_out int = 2, @bank_id_throttle int = 1

create table #invoice
(account_invoice_id int not null primary key,
cust_id int not null,
account_id int not null,
amount decimal(18,2) not null,
bank_id int null,
cust_payment_id int null,
account_payment_id int null,
bank_contract_id int null,

)

insert into #invoice (account_invoice_id, cust_id, account_id, amount, bank_id)
select ai.account_invoice_id, ai.cust_id, ai.account_id, ai.total_amount - isnull(ap.payment_amount, 0), gabfa.bank_id
from account_invoice ai
left join dbo.cds_fn_GetActiveBankForAccount (ai.account_id, ai.cust_id, @bank_id_throttle) gabfa on gabfa.account_id = ai.account_id

left join
	(select ap.account_invoice_id, sum(ap.payment_amount) [payment_amount]
	from account_payment ap
	join cust_payment cp on ap.cust_payment_id = cp.cust_payment_id
	join cust_payment_status cps on cp.cust_payment_status_id = cps.cust_payment_status_id
	where cps.code in ('NEW','PENDING','PAID')
	group by ap.account_invoice_id) ap on ai.account_invoice_id = ap.account_invoice_id
left join
	(select account_invoice_id, sum(payment_amount) [payment_amount]
	from account_payment 
	group by account_invoice_id) p on ai.account_invoice_id = p.account_invoice_id
where cast(isnull(ai.override_due_date,ai.due_date) as date) between dateadd(day,-@days_out,getdate()) and dateadd(day,@days_out,getdate())
and ai.account_invoice_payment_status_id is null
and ai.total_amount > isnull(ap.payment_amount,0)
and ai.total_amount > isnull(p.payment_amount,0)
order by ai.account_invoice_id

create table #allocation
(account_payment_id int not null primary key,
account_id int not null,
cust_payment_id int not null,
payment_amount decimal(18,2) not null)

insert into #allocation (account_payment_id, account_id, cust_payment_id, payment_amount)
select ap.account_payment_id, ap.account_id, ap.cust_payment_id, ap.payment_amount
from account_payment ap
join cust_payment cp on ap.cust_payment_id = cp.cust_payment_id
join cust_payment_status cps on cp.cust_payment_status_id = cps.cust_payment_status_id
where ap.account_invoice_id is null
and cps.code = 'PAID'
and ap.account_id in (select account_id from #invoice)

set nocount on

declare @cust_id int, 
		@account_id int, 
		@account_invoice_id int, 
		@amount decimal(18,2), 
		@payment_amount decimal(18,2), 
		@cust_payment_id int, 
		@account_payment_id int,
		@cust_payment_type_id int = (select cust_payment_type_id from cust_payment_type where code = 'INTERNAL_BANK_TRANSACTION')

while exists (select * from #invoice i join #allocation a on i.account_id = a.account_id)
begin
	select top 1 @account_invoice_id = i.account_invoice_id, @account_payment_id = a.account_payment_id, @cust_payment_id = a.cust_payment_id,
		@amount = i.amount, @payment_amount = a.payment_amount, @account_id = i.account_id
	from #invoice i 
	join #allocation a on i.account_id = a.account_id
	where i.amount > 0
	order by i.account_invoice_id, a.payment_amount

	if @amount >= @payment_amount
	begin
		update account_payment set account_invoice_id = @account_invoice_id where account_payment_id = @account_payment_id

		delete #allocation where account_payment_id = @account_payment_id

		update #invoice set amount -= @payment_amount where account_invoice_id = @account_invoice_id
	end
	else
	begin
		update account_payment set payment_amount -= @amount where account_payment_id = @account_payment_id

		update #allocation set payment_amount -= @amount where account_payment_id = @account_payment_id

		exec cds_InsertAccountPayment @cust_payment_id = @cust_payment_id, @account_id = @account_id, @payment_amount = @amount, @account_invoice_id = @account_invoice_id

		delete #invoice where account_invoice_id = @account_invoice_id
	end
end

delete #invoice where amount = 0

declare cust_payment_cursor cursor for
select cust_id, sum(amount) [payment_amount]
from #invoice
where bank_id is not null and bank_contract_id is not null
group by cust_id

open cust_payment_cursor
fetch next from cust_payment_cursor into @cust_id, @payment_amount
while @@FETCH_STATUS = 0
begin
	exec cds_InsertCustPayment @cust_id = @cust_id, @cust_payment_type_id = @cust_payment_type_id, @payment_amount = @payment_amount, @cust_payment_id = @cust_payment_id output, @bank_contract_id = @bank_contract_id

	update #invoice set cust_payment_id = @cust_payment_id where cust_id = @cust_id

	fetch next from cust_payment_cursor into @cust_id, @payment_amount
end

close cust_payment_cursor
deallocate cust_payment_cursor

declare account_payment_cursor cursor for
select account_invoice_id, account_id, cust_payment_id, amount [payment_amount]
from #invoice
where cust_payment_id is not null

open account_payment_cursor
fetch next from account_payment_cursor into @account_invoice_id, @account_id, @cust_payment_id, @payment_amount
while @@FETCH_STATUS = 0
begin
	exec cds_InsertAccountPayment @cust_payment_id = @cust_payment_id, @account_id = @account_id, @payment_amount = @payment_amount, @account_invoice_id = @account_invoice_id, @account_payment_id = @account_payment_id output

	update #invoice set account_payment_id = @account_payment_id where account_invoice_id = @account_invoice_id

	fetch next from account_payment_cursor into @account_invoice_id, @account_id, @cust_payment_id, @payment_amount
end

close account_payment_cursor
deallocate account_payment_cursor

drop table #invoice
drop table #allocation
go

