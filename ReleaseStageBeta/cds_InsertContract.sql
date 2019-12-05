use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter procedure dbo.cds_InsertContract @product_id int, @start_date date ,@email	varchar(255), @bank_account varchar(100),@account_num varchar(50),@facility_id int, @commodity_id int, @personal_tax_num varchar(100) ,@business_tax_num varchar(100)
,@Process varchar(255) = 'cds_InsertContract' , @contract_id int = null output, @Error varchar(max) = null output, @signatory_ord_contact_id int = null, @ord_account_id int = null
as
declare
	@run_time               datetime = getdate(),
	@NEW_contract_status_id int      = (select contract_status_id from contract_status where code = 'NEW'),
	@NEW_sync_status_id     int      = (select sync_status_id from sync_status where code = 'NEW'),
	@bank_change_flag       bit      = 0,
	@account_change_flag    bit      = 0

select @Error = '', @contract_id = null

if @email is null
  set @Error += '; @email cannot be null'

if not exists(select product_id from product where product_id = @product_id)
  set @Error += '; @product_id must exist'

if not exists(select commodity_id from commodity where commodity_id = @commodity_id) and @commodity_id is not null
  set @Error  += '; @commodity_id must exist'

if not exists(select facility_id from facility where facility_id = @facility_id) and  @facility_id is not null
  set @Error += '; @facility_id must exist'

if not exists(select ord_contact_id from ord_contact where ord_contact_id = @signatory_ord_contact_id)
  set @Error += '; @signatory_ord_contact_id must exist'

if @Error = ''
begin
	if not exists(select ord_contact_id from ord_contact where ord_contact_id = @signatory_ord_contact_id and (email1 = @email or email2 = @email))
	  set @Error += '; @email does match  @signatory_ord_contact_id '
end


if @error is null
	select @bank_change_flag = case when isnull(oa.bank_account,'') <> isnull(c.bank_account,'') or isnull(b.bank_account_name,'') <> isnull(oa.bank_account_name,'') then 1 else 0 end,
		@account_change_flag = case when oa.account_num <> isnull(c.account_num,'') or isnull(oa.facility_id,0) <> isnull(c.facility_id,0) or oa.commodity_id <> isnull(c.commodity_id,0) or isnull(oa.personal_tax_num,'') <> isnull(c.personal_tax_num,'') or isnull(oa.business_tax_num,'') <> isnull(c.business_tax_num,'') then 1 else 0 end
	from ord_account oa
	join [contract] c on oa.contract_id = c.contract_id
	left join bank b on isnull(b.bank_account,'') = isnull(c.bank_account,'') and isnull(b.document_key,'') = isnull(c.document_key,'') --*****HACK THIS JOIN IS TEMPORARY NEEDED FOR MVP bank_account_name. WE DON'T WANT TO MESS WITH THE CONTRACT TABLE FOR THE MVP Release
	where oa.ord_account_id = @ord_account_id


if @Error = ''
  begin
		begin try
			insert into [contract] (contract_status_id, product_id, [start_date], inserted_date, proposed_flow_date, contract_email, sync_status_id,
											bank_account, account_num, facility_id, commodity_id, personal_tax_num, business_tax_num, signatory_ord_contact_id)
			select @NEW_contract_status_id, @product_id, @start_date, @run_time, cds.dbo.cds_fn_ProposedFlowDate(@run_time), @email email, @NEW_sync_status_id,
				@bank_account, @account_num	, @facility_id, @commodity_id, @personal_tax_num, @business_tax_num, @signatory_ord_contact_id

			set @contract_id = scope_identity()
		end try
		begin catch

			set @Error = error_message()
			execute dba_insertprocerror @Process, @Error
		end catch
	end
go

