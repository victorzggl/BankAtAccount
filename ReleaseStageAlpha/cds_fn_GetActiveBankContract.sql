use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function dbo.cds_fn_GetActiveBankContract (@bank_id int = null, @cust_id int = null, @bank_contract_id int = null)
returns @active_bank_contract table
(
	bank_contract_id int not null primary key,
	cust_id          int not null,
	bank_id          int not null
)
as
begin

	insert into @active_bank_contract (bank_contract_id, cust_id, bank_id)
	select bc.bank_contract_id, bc.cust_id, bc.bank_id
	from bank_contract bc
	join bank_contract_status bcs on bcs.bank_contract_status_id = bc.bank_contract_status_id
	where bc.bank_id = isnull(@bank_id, bc.bank_id) and bc.cust_id = isnull(@cust_id, bc.cust_id) and bc.bank_contract_id = isnull(@bank_contract_id, bc.bank_contract_id)
	and bc.end_date is null
	and bc.cust_id is not null
	and bcs.code = 'ACTIVE'

	return;
end
go