use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[cds_InsertBank]

	@description varchar(200),
	@bank_id int = null output,
	@error varchar(500) = null output,
	@bank_contract_id int
as
declare
	@bank_status_NEW int = (select bank_status_id from bank_status where code = 'NEW'),
	@ord_source_id int = (select ord_source_id from ord_source where code = 'CDS'),
	@sync_status_id int = (select sync_status_id from sync_status where code = 'NEW'),

	@bank_reg_key varchar(100), @cust_id int, @bank_type_id int, @bank_account_name varchar(100), @signed_date datetime = null, @document_key varchar(100) = null, @bank_account varchar(100)

set @error = ''

if not exists (select * from bank_contract where bank_contract_id = @bank_contract_id)
	set @error += '; must be valid bank_contract_id'

if @error = ''
begin
	select @cust_id = bc.cust_id, @bank_reg_key = dbo.cds_fn_GetBankRegKey(@bank_contract_id), @bank_type_id = bc.bank_type_id, @bank_account = bc.bank_account, @bank_account_name = bc.bank_account_name, @bank_id = b.bank_id, @signed_date = bc.signed_date, @document_key = bc.document_key
	from bank_contract bc
	left join bank b on isnull(b.bank_id, 0) = isnull(bc.bank_id, 0) and b.cust_id = bc.cust_id and b.bank_account = bc.bank_account
	where bc.bank_contract_id = @bank_contract_id

	if @bank_id is null
	begin
		if not exists (select * from bank_type where bank_type_id = @bank_type_id)
			set @error += '; must be valid bank_type_id'

		if not exists (select * from sync_status where sync_status_id = @sync_status_id)
			set @error += '; must be valid sync_status_id'

		if not exists (select * from cust where cust_id = @cust_id)
			set @error += '; must be valid cust_id'

		if @bank_account is null
			set @error += '; bank_account cannot be blank'

		if @cust_id is not null and @bank_account in ('IT05S0103024801000001003495','IT14X0103024801000001003305','IT19C0103024801000000990063','IT38E0103024801000000990156','IT03X0103024801000000993512')
			set @error += '; bank_account not valid for customer use'

		if nullif(@bank_account_name,'') is null
			set @error += '; bank_account_name cannot be null'

		if exists(select 1 from bank_contract_status bcs join bank_contract bc on bc.bank_contract_status_id = bcs.bank_contract_status_id where bc.bank_contract_id = @bank_contract_id and (bcs.code = 'INACTIVE' or bc.end_date is not null) )
			set @error += '; bank_contract is no longer active'
	end
end

if @error = ''
begin
	if @bank_id is null
	begin
		insert into bank (cust_id, bank_type_id, bank_status_id, [description], bank_reg_key, bank_account, sync_status_id, ord_source_id, signed_date, document_key, bank_account_name)
		select @cust_id, @bank_type_id, @bank_status_NEW, @description, @bank_reg_key, @bank_account, @sync_status_id, @ord_source_id, @signed_date, @document_key, @bank_account_name

		set @bank_id = SCOPE_IDENTITY()
	end
end

if @error = ''
	set @error = null
go

