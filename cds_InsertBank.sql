
CREATE procedure [dbo].[cds_InsertBank]
	@csr_id int = null,
	@cust_id int = null,
	@bank_type_id int,
	@bank_reg_key varchar(100),
	@bank_account varchar(100),
	@description varchar(200),
	@sync_status_id int = null,
	@import_bank_id int = null,
	@ord_source_id int = null,
	@signed_date datetime = null,
	@document_key varchar(100) = null,
	@bank_id int = null output,
	@error varchar(500) = null output,
	@bank_account_name varchar(100)
as

declare @bank_status_NEW int = (select bank_status_id from bank_status where code = 'NEW')

if @sync_status_id is null
	set @sync_status_id = (select sync_status_id from sync_status where code = 'NEW')

if @ord_source_id is null
	set @ord_source_id = (select ord_source_id from ord_source where code = 'CDS')

set @error = ''

if not exists (select * from bank_type where bank_type_id = @bank_type_id)
	set @error += '; must be valid bank_type_id'

if not exists (select * from sync_status where sync_status_id = @sync_status_id)
	set @error += '; must be valid sync_status_id'

if not exists (select * from ord_source where ord_source_id = @ord_source_id)
	set @error += '; must be valid ord_source_id'

if (@csr_id is null and @cust_id is null)
	or (@csr_id is not null and @cust_id is not null)
	or (@cust_id is null and not exists (select * from csr where csr_id = @csr_id))
	or (@csr_id is null and not exists (select * from cust where cust_id = @cust_id))
	set @error += '; must be valid csr_id XOR cust_id'

if @bank_reg_key is null
	set @error += '; bank_reg_key cannot be blank'

if @bank_account is null
	set @error += '; bank_account cannot be blank'

if @cust_id is not null and @bank_account in ('IT05S0103024801000001003495','IT14X0103024801000001003305','IT19C0103024801000000990063','IT38E0103024801000000990156','IT03X0103024801000000993512')
	set @error += '; bank_account not valid for customer use'

if nullif(@bank_account_name,'') is null
	begin
		set @error += '; bank_account_name cannot be null'
	end

set @bank_id = null

if @error = ''
begin
	select @bank_id = bank_id from bank where cust_id = @cust_id and bank_account = @bank_account and @bank_id is null
	select @bank_id = bank_id from bank where csr_id = @csr_id and bank_account = @bank_account and @bank_id is null

	if @bank_id is null
	begin
		insert into bank (csr_id, cust_id, bank_type_id, bank_status_id, [description], bank_reg_key, bank_account, sync_status_id, import_bank_id, ord_source_id, signed_date, document_key, bank_account_name)
		select @csr_id, @cust_id, @bank_type_id, @bank_status_NEW, @description, @bank_reg_key, @bank_account, @sync_status_id, @import_bank_id, @ord_source_id, @signed_date, @document_key, @bank_account_name

		set @bank_id = SCOPE_IDENTITY()
	end
end

if @error = ''
	set @error = null
go

