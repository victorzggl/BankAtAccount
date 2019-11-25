

CREATE procedure [dbo].[send_UpdateDocumentKey] @table_name varchar(50), @primary_key int, @document_key varchar(100), @error_message varchar(max) = null
as

declare @ProcName varchar(100) = 'send_UpdateDocumentKey',
		@error varchar(500),
		@send_status_HTML_CREATED int = (select send_status_id from send_status where code = 'HTML_CREATED'),
		@send_status_PDF_CREATED int = (select send_status_id from send_status where code = 'PDF_CREATED'),
		@send_status_id int = (select send_status_id from send_status where code = case when @error_message is null then 'DOCUMENT_CREATED' else 'DOCUMENT_FAILED' end)

if @document_key = ''
	set @document_key = null

if @table_name = 'account_send'
begin
	if not exists (	select 1
					from account_send s
					join cds.dbo.html_template_version htv on s.html_template_version_id = htv.html_template_version_id
					join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
					join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
					where s.account_send_id = @primary_key
					and (s.send_status_id = @send_status_PDF_CREATED
						or (s.send_status_id = @send_status_HTML_CREATED and htt.create_pdf_flag = 0)))
		set @error = 'account_send does not exist in PDF_CREATED status'

	if @error is null
	begin
		begin try
			update account_send
			set document_key = @document_key, 
				send_status_id = @send_status_id, 
				sent_date = case when @error_message is null then getdate() else sent_date end
			where account_send_id = @primary_key

			if @error_message is not null
				insert into send_error (table_name, table_id, error) select @table_name, @primary_key, @error_message
		end try
		begin catch
			set @error = 'account_send update failed'
		end catch
	end
end
else if @table_name = 'csr_send'
begin
	if not exists (	select 1
					from csr_send s
					join cds.dbo.html_template_version htv on s.html_template_version_id = htv.html_template_version_id
					join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
					join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
					where s.csr_send_id = @primary_key
					and (s.send_status_id = @send_status_PDF_CREATED
						or (s.send_status_id = @send_status_HTML_CREATED and htt.create_pdf_flag = 0)))
		set @error = 'csr_send does not exist in PDF_CREATED status'

	if @error is null
	begin
		begin try
			update csr_send set document_key = @document_key, send_status_id = @send_status_id where csr_send_id = @primary_key

			if @error_message is not null
				insert into send_error (table_name, table_id, error) select @table_name, @primary_key, @error_message
		end try
		begin catch
			set @error = 'csr_send update failed'
		end catch
	end

	if @error is null
	begin
		begin try
			update cc set document_key = @document_key
			from cds.dbo.csr_contract cc
			join csr_send cs on cc.csr_contract_id = cs.csr_contract_id
			join cds.dbo.html_template_version htv on cs.html_template_version_id = htv.html_template_version_id
			join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
			join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
			where cs.csr_send_id = @primary_key
			and htt.code = 'NEW_ASSOCIATE_CONTRACT'
		end try
		begin catch
			set @error = 'csr_contract update failed for document_key'
		end catch
	end

	if @error is null
	begin
		begin try
			update cc set pec_sent_date = getdate()
			from cds.dbo.csr_contract cc
			join csr_send cs on cc.csr_contract_id = cs.csr_contract_id
			join send_status ss on cs.send_status_id = ss.send_status_id
			join cds.dbo.html_template_version htv on cs.html_template_version_id = htv.html_template_version_id
			join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
			join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
			where cs.csr_send_id = @primary_key
			and htt.code = 'ASSOCIATE_GOV_ID_PEC_EMAIL'
			and ss.code = 'DOCUMENT_CREATED'
		end try
		begin catch
			set @error = 'csr_contract update failed for pec_sent_date'
		end catch
	end

-- 2019/03/21 pgp update csr_card (cs.csr_card_id will be null for csr_contract documents) with the new @document_key
	if @error is null
	begin
		begin try
			update cc set document_key = @document_key
			from cds.dbo.csr_card cc
			join csr_send cs on cc.csr_card_id = cs.csr_card_id
			where cs.csr_send_id = @primary_key
		end try
		begin catch
			set @error = 'csr_card_id update failed for document_key'
		end catch
	end

end
else if @table_name = 'cust_send'
begin
	if not exists (	select 1
					from cust_send s
					join cds.dbo.html_template_version htv on s.html_template_version_id = htv.html_template_version_id
					join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
					join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
					where s.cust_send_id = @primary_key
					and (s.send_status_id = @send_status_PDF_CREATED
						or (s.send_status_id = @send_status_HTML_CREATED and htt.create_pdf_flag = 0)))
		set @error = 'cust_send does not exist in PDF_CREATED status'

	if @error is null
	begin
		begin try
			update cust_send set document_key = @document_key, send_status_id = @send_status_id where cust_send_id = @primary_key

			if @error_message is not null
				insert into send_error (table_name, table_id, error) select @table_name, @primary_key, @error_message
		end try
		begin catch
			set @error = 'cust_send update failed'
		end catch
	end
end
else if @table_name = 'ord_account_send'
begin
	if not exists (	select 1
					from ord_account_send s
					join cds.dbo.html_template_version htv on s.html_template_version_id = htv.html_template_version_id
					join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
					join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
					where s.ord_account_send_id = @primary_key
					and (s.send_status_id = @send_status_PDF_CREATED
						or (s.send_status_id = @send_status_HTML_CREATED and htt.create_pdf_flag = 0)))
		set @error = 'ord_account_send does not exist in PDF_CREATED status'

	if @error is null
	begin
		begin try
			update ord_account_send 
			set document_key = @document_key, 
				send_status_id = @send_status_id,
				sent_date = case when @error_message is null then getdate() else sent_date end
			where ord_account_send_id = @primary_key

			if @error_message is not null
				insert into send_error (table_name, table_id, error) select @table_name, @primary_key, @error_message
		end try
		begin catch
			set @error = 'ord_account_send update failed'
		end catch
	end

	if @error is null
	begin
		begin try
			update c set document_key = @document_key
			from cds.dbo.[contract] c
			join ord_account_send s on c.contract_id = s.contract_id
			where s.ord_account_send_id = @primary_key
		end try
		begin catch
			set @error = 'contract update failed'
		end catch
	end
end
else if @table_name = 'ord_cust_send'
begin
	if not exists (	select 1
					from ord_cust_send s
					join cds.dbo.html_template_version htv on s.html_template_version_id = htv.html_template_version_id
					join cds.dbo.html_template ht on htv.html_template_id = ht.html_template_id
					join cds.dbo.html_template_type htt on ht.html_template_type_id = htt.html_template_type_id
					where s.ord_cust_send_id = @primary_key
					and (s.send_status_id = @send_status_PDF_CREATED
						or (s.send_status_id = @send_status_HTML_CREATED and htt.create_pdf_flag = 0)))
		set @error = 'ord_cust_send does not exist in PDF_CREATED status'

	if @error is null
	begin
		begin try
			update ord_cust_send set document_key = @document_key, send_status_id = @send_status_id where ord_cust_send_id = @primary_key

			if @error_message is not null
				insert into send_error (table_name, table_id, error) select @table_name, @primary_key, @error_message
		end try
		begin catch
			set @error = 'ord_cust_send update failed'
		end catch
	end
end
else
begin
	set @error = 'table name is not valid @table_name = ' + isnull(@table_name,'IS NULL')
end

if @error is not null
begin
	set @error += ' @primary_key = ' + isnull(cast(@primary_key as varchar(50)),'IS NULL')
	exec dba_InsertProcError @ProcName = @ProcName, @InternalError = @error
end

go

