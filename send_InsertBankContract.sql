use CDS_Send
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
go

CREATE procedure [dbo].[send_InsertBankContract]
as

set nocount on

declare @ProcName varchar(100) = 'send_InsertBankContract',
		@error varchar(500),
		@today date = getdate(),
		@send_status_NOT_DRIVER int = (select send_status_id from send_status where code = 'NOT_DRIVER') ,
		@bank_contract_status_PENDING int = (select bank_contract_status_id from cds.dbo.bank_contract_status where code = 'PENDING'),
		@bank_contract_id int,
		@cust_send_id int

create table #cust_send
(send_status_id int not null,
cust_id int not null,
html_template_type varchar(50) not null,
html_template_version_id int not null,
from_email varchar(300) null,
to_email varchar(300) null,
cust_language_id int null,
account_language_id int null,
bank_reg_key varchar(100) null,
bank_contract_id int null,
account_id int null,

)

insert into #cust_send (send_status_id, cust_id, html_template_type, html_template_version_id, from_email, to_email, cust_language_id, account_language_id, bank_reg_key, bank_contract_id, account_id)
select htt.initial_send_status_id [send_status_id], c.cust_id, htt.code [html_template_type], htv.html_template_version_id, ee.email [from_email], bc.signatory_email [to_email], c.language_id [cust_language_id], a.language_id [account_language_id], bc.bank_reg_key, bc.bank_contract_id, abc.account_id
from cds.dbo.bank_contract bc
join cds.dbo.bank_contract_status bcs on bcs.bank_contract_status_id = bc.bank_contract_status_id
join cds.dbo.account_bank_contract abc on abc.bank_contract_id = bc.bank_contract_id
join cds.dbo.cust c on c.cust_id = bc.cust_id
join cds.dbo.account a on a.account_id = abc.account_id
join cds.dbo.html_template ht on c.esco_id = ht.esco_id
join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
join cds.dbo.html_template_version htv on ht.html_template_id = htv.html_template_id
join cds.dbo.esco_email ee on c.esco_id = ee.esco_id and ht.email_type_id = ee.email_type_id
join cds.dbo.esco_state es on a.esco_id = es.esco_id and a.state_id = es.state_id
where bcs.code = 'NEW'
and bc.signed_date is null
and htt.code = 'BANK_MANDATE'
and @today between htv.[start_date] and isnull(htv.end_date, @today)



declare cust_send_cursor cursor for
select distinct bank_contract_id
from #cust_send
order by bank_contract_id

open cust_send_cursor
fetch next from cust_send_cursor into @bank_contract_id
while @@FETCH_STATUS = 0
begin
	begin try
		begin transaction

		insert into cust_send (send_status_id, cust_id,  html_template_version_id, from_email, to_email, bank_reg_key, language_id, bank_contract_id)
		select distinct send_status_id, cust_id, html_template_version_id, from_email, to_email, bank_reg_key, cust_language_id, bank_contract_id
		from #cust_send
		where bank_contract_id = @bank_contract_id
		and html_template_type in ('BANK_MANDATE')

		set @cust_send_id = SCOPE_IDENTITY()

		insert into account_send (cust_send_id, send_status_id, account_id, html_template_version_id, language_id)
		select @cust_send_id [ord_cust_send_id], @send_status_NOT_DRIVER [send_status_id], account_id, html_template_version_id, account_language_id
		from #cust_send
		where cust_id = @bank_contract_id
		and html_template_type in ('BANK_MANDATE')

		if @@ROWCOUNT = 0
			raiserror(10,1,1)

		update b set bank_contract_status_id = @bank_contract_status_PENDING
		from cds.dbo.bank_contract b
		join #cust_send s on b.bank_contract_id = s.bank_contract_id
		where s.bank_contract_id = @bank_contract_id

		commit transaction
	end try
	begin catch
		rollback transaction
		set @error = 'cursor failed on insert/update @bank_contract_id = ' + cast(@bank_contract_id as varchar(50))
		exec dba_InsertProcError @ProcName = @ProcName, @InternalError = @error
	end catch

	fetch next from cust_send_cursor into @bank_contract_id
end

close cust_send_cursor
deallocate cust_send_cursor

drop table #cust_send
go

