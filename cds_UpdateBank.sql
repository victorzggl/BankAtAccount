use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[cds_UpdateBank]
	@cust_id int = null,
	@bank_type_id int,
	@bank_reg_key varchar(100),
	@bank_account varchar(100),
	@description varchar(200),
	@ord_source_id int = null,
	@signed_date datetime = null,
	@document_key varchar(100) = null,
	@bank_id int = null,
	@error varchar(500) = null output,
	@bank_account_name varchar(100)
as
set @bank_id = null

declare @bank_status_NEW int = (select bank_status_id from bank_status where code = 'NEW'),
		@bank_status_NEEDS_REVIEW int = (select bank_status_id from bank_status where code = 'NEEDS_REVIEW')

if @ord_source_id is null
	set @ord_source_id = (select ord_source_id from ord_source where code = 'CDS')

set @error = ''

if not exists (select 1 from bank_type where bank_type_id = @bank_type_id)
	set @error += '; must be valid bank_type_id'

if not exists (select 1 from ord_source where ord_source_id = @ord_source_id)
	set @error += '; must be valid ord_source_id'

if nullif(@document_key,'') is null
	set @error += '; document_key cannot be null'

if @signed_date is null
	set @error += '; signed_date cannot be null'

select @cust_id = cust_id, @bank_account = bank_account, @bank_id = bank_id
from bank b
where cust_id = @cust_id
and bank_account = @bank_account

if @bank_id is null
	set @error += '; must be valid cust_id and bank_account'

if @cust_id is not null and @bank_account in ('IT05S0103024801000001003495','IT14X0103024801000001003305','IT19C0103024801000000990063','IT38E0103024801000000990156','IT03X0103024801000000993512')
	set @error += '; bank_account not valid for customer use'

if nullif(@bank_account_name,'') is null
	begin
		set @error += '; bank_account_name cannot be null'
	end

if @error = ''
begin
	if @bank_id is null
	begin
		update b set
		bank_account_name = isnull(nullif(@bank_account_name, ''), bank_account_name),
		bank_authorization_key = null,
		bank_account_key = null,
		bank_status_date = getdate(),
		validated_date = null,
		validated_flag = 0,
		updated_date = getdate(),
		bank_status_id = @bank_status_NEW,
		bank_reg_key = isnull(nullif(@bank_reg_key, ''), bank_reg_key),
		description = isnull(nullif(@description, ''), description),
		signed_date = @signed_date
		from bank b
		where b.bank_id = @bank_id
	end
end
else
begin
	update b set error = @error, bank_status_id = @bank_status_NEEDS_REVIEW from bank b where bank_id = @bank_id and error <> @error
end
go

