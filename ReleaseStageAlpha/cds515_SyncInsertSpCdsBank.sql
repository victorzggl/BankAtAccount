use CDS_515
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure dbo.cds515_SyncInsertSpCdsBank as

declare
	@max_id                         int, @min_id int,
	@csr_id                         int
	, @cust_id                      int
	, @bank_type_id                 int
	, @description                  varchar(200)
	, @sync_status_id               int
	, @import_bank_id               int
	, @cds_bank_id                  int
	, @order_source_id              int
	, @error                        varchar(max)
	, @UPDATED_sync_status_id       int          = (select sync_status_id from sync_status where code = 'UPDATED')
	, @SYNCED_sync_status_id        int          = (select sync_status_id from sync_status where code = 'SYNCED')
	, @FAILED_INSERT_sync_status_id int          = (select sync_status_id from sync_status where code = 'FAILED_INSERT')
	, @ProcName                     varchar(100) = 'cds515_SyncInsertSpCdsBank'
	, @InternalError                varchar(1000)
	, @bank_account                 varchar(100)
	, @validated_flag               bit
	, @bank_reg_key                 varchar(100)
	, @bank_account_name            varchar(100)
select @max_id = max(id) , @min_id = min(id)
from #bank
where 1 = 0 -- SP DESTROYED NO INSERTS ALLOWED.
while @min_id <= @max_id
	begin
		begin try
		select @sync_status_id = @SYNCED_sync_status_id, @bank_type_id = bank_type_id, @order_source_id = order_source_id, @import_bank_id = bank_id, @cust_id = cust_id,@description = [description], @bank_account = bank_account
				 , @error = null, @cds_bank_id = null, @validated_flag = validated_flag, @bank_reg_key = bank_reg_key, @bank_account_name = bank_account_name
			from #bank a
			where a.id = @min_id
			/*exec cds.dbo.cds_InsertBank @csr_id = null, @cust_id = @cust_id, @bank_type_id = @bank_type_id,@description = @description,@sync_status_id = @UPDATED_sync_status_id
			, @import_bank_id = @import_bank_id, @ord_source_id = @order_source_id, @bank_reg_key = @bank_reg_key, @bank_account = @bank_account, @bank_id = @cds_bank_id output, @error = @error output
			, @bank_account_name = @bank_account_name*/
			if nullif(@error,'') is not null
				begin
					;throw 50515, @error, 1
				end
			else
				begin
					update a set cds_sync_status_id = @sync_status_id from #bank a where id = @min_id
				end

		end try
		begin catch
			set @sync_status_id = @FAILED_INSERT_sync_status_id
			set @InternalError = 'insert bank record from cds_515 to cds for cds_515.bank_id = ' + cast(@import_bank_id as varchar(10) )
			update a set cds_sync_status_id = @sync_status_id from #bank a where id = @min_id
			exec dba_InsertProcError @ProcName = @ProcName , @InternalError = @InternalError
		end catch
		set @min_id += 1
	end

go

