
CREATE procedure [dbo].[cds515_SyncPreOp] @table_name varchar(255), @sync_operation_sync_status_id int, @string_output_only_flag bit = 0
															 	,@SyncPreOp_insert_string_output varchar(max) = '' output
																,@SyncPreOp_select_string_output varchar(max) = '' output
																,@SyncPreOp_alter_temp_table_string varchar(max) = '' output
																as
	declare
@NEW_sync_status_id int = (select sync_status_id from sync_status where code = 'NEW')
,@FAILED_INSERT_sync_status_id int = (select sync_status_id from sync_status where code = 'FAILED_INSERT')
,@CDS_515_order_source_id int = (select order_source_id from order_source where code = 'CDS_515')
,@CDS_order_source_id int = (select order_source_id from order_source where code = 'CDS')
,@windows_line_break varchar(10) =char(13)+char(10)
,@max_id int
,@min_id int
,@Error varchar(max)
,@Process varchar(255) = ''
if @string_output_only_flag = 1
	begin
		if @sync_operation_sync_status_id = @NEW_sync_status_id
			begin
				if @table_name = 'order_account'
					begin
						set @SyncPreOp_alter_temp_table_string = 'alter table #' + @table_name + @windows_line_break +
							'add sales_corp_id int' + @windows_line_break +
							', ord_channel_id int ' + @windows_line_break +
							', ord_sale_type_id int ' + @windows_line_break +
							', ord_account_pay_status_id int ' + @windows_line_break +
							', csr_id int ' + @windows_line_break +
							', language_id int ' + @windows_line_break +
							', ord_verif_status_id int ' + @windows_line_break +
							', ord_post_close_status_id int ' + @windows_line_break +
							', utility_sub_id int ' + @windows_line_break
						set @SyncPreOp_insert_string_output =
							'/*begin SyncPreOp_insert_string_output*/ ,sales_corp_id, ord_channel_id, ord_sale_type_id, ord_account_pay_status_id, csr_id, language_id, ord_verif_status_id , ord_post_close_status_id,utility_sub_id /*end SyncPreOp_insert_string_output*/'
						set @SyncPreOp_select_string_output = @SyncPreOp_insert_string_output
					end
				if @table_name = 'order_cust'
					begin
						set @SyncPreOp_alter_temp_table_string = 'alter table #' + @table_name + @windows_line_break +
							'add esco_id int' + @windows_line_break
						set @SyncPreOp_insert_string_output =
							'/*begin SyncPreOp_insert_string_output*/ , esco_id /*end SyncPreOp_insert_string_output*/'
						set @SyncPreOp_select_string_output = @SyncPreOp_insert_string_output
					end
				if @table_name = 'csr'
					begin
						set @SyncPreOp_alter_temp_table_string = 'alter table #' + @table_name + @windows_line_break +
							'add unit_id int' + @windows_line_break +
							', sales_corp_id int' + @windows_line_break

						set @SyncPreOp_insert_string_output =
							'/*begin SyncPreOp_insert_string_output*/ , unit_id, sales_corp_id /*end SyncPreOp_insert_string_output*/'
						set @SyncPreOp_select_string_output = @SyncPreOp_insert_string_output
					end
				if @table_name = 'order_contact'
					begin
						set @SyncPreOp_alter_temp_table_string = 'alter table #' + @table_name + @windows_line_break +
-- 							'add ord_contact_type_id int' + @windows_line_break +
							'add contact_title_id int' + @windows_line_break

						set @SyncPreOp_insert_string_output =
							'/*begin SyncPreOp_insert_string_output*/ , contact_title_id /*end SyncPreOp_insert_string_output*/'
						set @SyncPreOp_select_string_output = @SyncPreOp_insert_string_output
					end
			end
	end
else
	begin
		if @sync_operation_sync_status_id = @NEW_sync_status_id
			begin
				if @table_name = 'order_contact'
					begin
/*						update o set ord_contact_type_id = b.ord_contact_type_id
						from #order_contact o
						cross apply cds.dbo.ord_contact_type b
						where b.code = 'DM'*/
						update a set contact_title_id = b.contact_title_id
						from #order_contact a
						join contact_title b on a.title = b.code

						update o set contact_title_id = b.contact_title_id
						from #order_contact o
						cross apply cds.dbo.contact_title b
						where b.code = 'Other'
					end
				if @table_name = 'csr'
					begin

						update a set personal_tax_num = upper(personal_tax_num), business_tax_num = upper(business_tax_num)
						from #csr a
						where a.row_source_order_source_id = @CDS_515_order_source_id


						update a set csr_num = left(newid(),20)
						from #csr a
						where a.row_source_order_source_id = @CDS_515_order_source_id

						update o set unit_id = b.unit_id
						from #csr o
						cross apply cds.dbo.unit b
						where b.code = 'DEFAULT_UNIT'

						update o set sales_corp_id = b.sales_corp_id
						from #csr o
						cross apply cds.dbo.sales_corp b
						where b.code = 'CDS_515'
					end
				if @table_name = 'bank'
					begin
					if exists(select 1 from #bank where row_source_order_source_id <> @CDS_order_source_id)
						exec cds515_SyncInsertSpCdsBank
					end
				if @table_name = 'order_account'
					begin
						update o set sales_corp_id = b.sales_corp_id
						from #order_account o
						cross apply cds.dbo.sales_corp b
						where b.code = 'CDS_515'
						and nullif(o.sales_corp_id,'') is null

						update o set vat_num = upper(o.vat_num),personal_tax_num = upper(o.personal_tax_num)
						from #order_account o

						update o set utility_id = b.utility_id
						from #order_account o
						cross apply cds.dbo.utility b
						where b.code = 'AXPO'
						and nullif(o.utility_id,'') is null

						update o set ord_channel_id = b.ord_channel_id
						from #order_account o
						cross apply cds.dbo.ord_channel b
						where b.code = 'WEB'
						and nullif(o.ord_channel_id,'') is null

						update o set ord_account_pay_status_id = b.ord_account_pay_status_id
						from #order_account o
						cross apply cds.dbo.ord_account_pay_status b
						where b.code = 'PAYABLE'
						and nullif(o.ord_account_pay_status_id,'') is null


						update o set ord_post_close_status_id = b.ord_post_close_status_id
						from #order_account o
						cross apply cds.dbo.ord_post_close_status b
						where b.code = 'NEW'
						and nullif(o.ord_post_close_status_id,'') is null

						update o set ord_verif_status_id = b.ord_verif_status_id
						from #order_account o
						cross apply cds.dbo.ord_verif_status b
						where b.code = 'NEW'
						and nullif(o.ord_verif_status_id,'') is null

						update o set ord_account_pay_status_id = b.ord_account_pay_status_id
						from #order_account o
						cross apply cds.dbo.ord_account_pay_status b
						where b.code = 'PAYABLE'
						and nullif(o.ord_account_pay_status_id,'') is null

						update o set ord_sale_type_id = ost.ord_sale_type_id
						from cds.dbo.ord_sale_type ost
						join #order_account o on o.facility_id = ost.facility_id and ost.commodity_id = o.commodity_id
						where ost.green_flag = 0
						and ost.winback_flag = 0
						and retention_flag = 0
						and nullif(o.ord_sale_type_id,'') is null

						update o set csr_id = c.cds_csr_id
						from #order_account o
						join order_cust oc on o.order_cust_id = oc.cds_ord_cust_id
						join csr c on oc.csr_id = c.csr_id and oc.order_source_id = c.order_source_id
						where nullif(o.csr_id,'') is null

						update o set language_id = b.language_id
						from #order_account o
						join cds.dbo.ord_cust b on b.ord_cust_id = o.order_cust_id
						where nullif(o.language_id, '') is null

						update o set language_id = b.default_language_id
						from #order_account o
						join cds.dbo.esco b on b.esco_id = o.esco_id
						where nullif(o.language_id,'') is null

						update o set utility_sub_id = uts.utility_sub_id
						from #order_account o
						left join CDS.dbo.utility_sub_prefix sp on sp.prefix = left(o.account_number,len(sp.prefix)) and sp.commodity_id = o.commodity_id
						left join cds.dbo.utility_sub uts on uts.utility_sub_id = sp.utility_sub_id
						where nullif(o.utility_sub_id,'') is null

						update o set [address] = ltrim(rtrim(isnull([address],'') ))
						from #order_account o

						set @Process = 'cds515_SyncPreOp-cds_InsertContract'
					 	declare @product_id int, @start_date date, @email varchar(255), @bank_account varchar(100),@account_num varchar(50),@facility_id int, @commodity_id int, @personal_tax_num varchar(100) ,@business_tax_num varchar(100)
						,@contract_id int
						,@FIXED_product_type_id int = (select product_type_id from cds.dbo.product_type where code = 'FIXED')
						,@ACTIVE_product_status_id int = (select product_status_id from cds.dbo.product_status where code = 'ACTIVE')
						,@WL_order_contact_type_id	int = (select order_contact_type_id from order_contact_type where code = 'WL')
						,@cds_515_order_account_id int
						,@cds_ord_cust_id int
						,@bank_account_name varchar(100)

						select @max_id = max(id) , @min_id = min(id) from #order_account
						while @min_id <= @max_id
							begin
								begin try
									set @Error = null
									set @cds_515_order_account_id = null
									set @contract_id = null
									set @cds_ord_cust_id = null

									set @cds_515_order_account_id = (select order_account_id from #order_account where id = @min_id and row_source_order_source_id = @CDS_515_order_source_id )

									select @contract_id = contract_id, @cds_ord_cust_id = order_cust_id
									from #order_account
									where id = @min_id

									if @cds_ord_cust_id is null
										begin
											set @Error = '@cds_ord_cust_id is null for some reason'
											;throw 50516, @Error , 1
										end
									if not exists (select 1 from cds.dbo.contract where contract_id = @contract_id and end_date is null )
										begin
											set @email = (select isnull(a.email1, a.email2) from order_contact a join cds.dbo.ord_cust b on a.order_cust_id = b.import_order_cust_id where b.ord_cust_id = @cds_ord_cust_id and a.contact_type_id = @WL_order_contact_type_id)
											if nullif(@email,'') is null
												begin
													set @Error = 'order_account contract_email missing for contract'
													delete from #order_account where id = @min_id
--													;throw 50517, @Error, 1
												end
											if nullif(@Error,'') is null
											 begin
													select @product_id = b.product_id, @start_date = oc.order_date, @bank_account = a.bank_account, @account_num = a.account_number, @facility_id = a.facility_id, @commodity_id = a.commodity_id, @personal_tax_num = a.personal_tax_num, @business_tax_num = a.vat_num
													,@bank_account_name = a.bank_account_name
													from #order_account a
													join cds.dbo.product b on b.utility_id = a.utility_id and b.esco_id = a.esco_id
													join cds.dbo.ord_cust oc on a.order_cust_id = oc.ord_cust_id
													where b.product_type_id = @FIXED_product_type_id
													and product_status_id = @ACTIVE_product_status_id
													and a.id = @min_id

													execute cds.dbo.cds_InsertContract @product_id	 = @product_id, @start_date = @start_date, @email = @email, @bank_account = @bank_account, @account_num = @account_num, @facility_id = @facility_id, @commodity_id = @commodity_id, @personal_tax_num = @personal_tax_num, @business_tax_num = @business_tax_num,@Process = @Process
														,@contract_id = @contract_id output,@Error = @Error output


													update #order_account set contract_id = @contract_id where id = @min_id
												end
												if nullif(@Error,'') is not null
													begin
														;throw 50518,@Error, 1
													end
												if not exists(select 1 from cds.dbo.contract where contract_id = @contract_id) and nullif(@Error,'') is null
													begin
													 set @Error ='@Error is null and @contract_id is null'
														;throw 50519,@Error, 1
													end
										end
								end try
								begin catch
									set @Error = @Process + ' order_account_id = '+ (select cast(order_account_id as varchar(50)) from #order_account where id = @min_id)
									execute dba_insertprocerror @Process, @Error

									update a set cds_sync_status_id = @FAILED_INSERT_sync_status_id
									from order_account a
									join #order_account b on a.order_account_id = b.order_account_id
									where b.id = @min_id

									delete a from #order_account a where id = @min_id

								end catch
								set @min_id += 1
							end
						declare
							@sync_table_name_map_id int = (select sync_table_name_map_id from sync_table_name_map where table_name = 'contract')
							,@row_source_order_source_id int = (select order_source_id from order_source where code = 'CDS')
							,@row_destination_order_source_id int = (select order_source_id from order_source where code ='CDS_515')
							,@return_sync_status_id int = (select sync_status_id from sync_status where code = 'SYNCED')
							,@throttle_num int = 500

						exec cds515_SyncTableMain @sync_table_name_map_id = @sync_table_name_map_id, @sync_operation_sync_status_id = @sync_operation_sync_status_id,
							@row_source_order_source_id = @row_source_order_source_id,@row_destination_order_source_id = @row_destination_order_source_id, @return_sync_status_id = @return_sync_status_id, @throttle_num = @throttle_num,
							@ProcName = 'SyncPreOp-InsertContractToCds515',@InternalError = 'Propagate Contract after inserting into CDS', @insert_sp_name = null, @debug_string = '', @dont_log_flag = 0,@no_execute_flag = 0
						 	set @row_source_order_source_id = @row_destination_order_source_id
						 	set @row_destination_order_source_id = (select order_source_id from order_source where code ='WEB_515_IT')
						exec cds515_SyncTableMain @sync_table_name_map_id = @sync_table_name_map_id, @sync_operation_sync_status_id = @sync_operation_sync_status_id,
							@row_source_order_source_id = @row_source_order_source_id,@row_destination_order_source_id = @row_destination_order_source_id, @return_sync_status_id = @return_sync_status_id, @throttle_num = @throttle_num,
							@ProcName = 'SyncPreOp-InsertContractToWeb515',@InternalError = 'Propagate Contract after inserting into CDS', @insert_sp_name = null, @debug_string = '', @dont_log_flag = 0,@no_execute_flag = 0
					end
				if @table_name = 'order_cust'
					begin
						update o set esco_id = b.esco_id
						from #order_cust o
						cross apply cds.dbo.esco b
						where b.code = 'GGL'


					end
			end
	end
go

