
create procedure cds_InsertContract @product_id int, @start_date date ,@email	varchar(255), @bank_account varchar(100),@account_num varchar(50),@facility_id int, @commodity_id int, @personal_tax_num varchar(100) ,@business_tax_num varchar(100)
,@Process varchar(255) = 'cds_InsertContract' , @contract_id int = null output ,@Error varchar(max) = null output
  as
declare @run_time datetime = getdate()
  ,@NEW_contract_status_id int = (select contract_status_id from contract_status where code = 'NEW')
	,@NEW_sync_status_id int = (select sync_status_id from sync_status where code = 'NEW')
	set @Error = ''
	set @contract_id = null
if @email is null
  set @Error = @Error + '@email cannot be null;'
if not exists(select product_id from product where product_id = @product_id)
  set @Error = @Error + '@product_id cannot be null;'
if not exists(select commodity_id from commodity where commodity_id = @commodity_id) and @commodity_id is not null
  set @Error = @Error + '@commodity_id is invalid;'
if not exists(select facility_id from facility where facility_id = @facility_id) and  @facility_id is not null
  set @Error = @Error + '@facility_id is invalid;'
if nullif(@Error,'') is null
  begin
		begin try
			insert into [contract] (contract_status_id, product_id, [start_date], inserted_date, proposed_flow_date, contract_email, sync_status_id,
											bank_account, account_num, facility_id, commodity_id, personal_tax_num, business_tax_num)
			select @NEW_contract_status_id, @product_id, @start_date, @run_time, cds.dbo.cds_fn_ProposedFlowDate(@run_time), @email email, @NEW_sync_status_id,
				@bank_account, @account_num	, @facility_id, @commodity_id, @personal_tax_num, @business_tax_num

			set @contract_id = scope_identity()
		end try
		begin catch
			set @Error = @Process + ':'+ isnull(@Error,'')
			execute dba_insertprocerror @Process, @Error
			set @Error = error_message()
		end catch
	end
go

