use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function dbo.cds_fn_GetActiveBankForAccount (@account_id int, @cust_id int, @bank_id_throttle int, @bank_account varchar(100) = null)
returns @active_bank_contract table
(
	account_id       int not null,
	bank_id          int not null,
	bank_contract_id int not null,
	primary key (account_id, bank_id)
)
as
begin
	if isnull(@bank_id_throttle, 0) = 0
		set @bank_id_throttle = 100

	;with aba as (
		select a.account_id, gabc.bank_id, min(abc.bank_contract_id) bank_contract_id /*in theory > 1 ACTIVE account_bank_contract for (cust_id, bank_id) could not exist, if it does handle it this way*/
		from account a
		join account_bank_contract abc on abc.account_id = a.account_id
		cross apply dbo.cds_fn_GetActiveBankContract (null, @cust_id, abc.bank_contract_id) gabc
		join bank b on b.bank_id = gabc.bank_id
		join bank_status bs on bs.bank_status_id = b.bank_status_id
		where a.account_id = @account_id
		and abc.active_flag = 1
		and bs.code = 'ACTIVE'
		and b.bank_account = isnull(@bank_account, b.bank_account)
		group by a.account_id, gabc.bank_id
	)
	insert into @active_bank_contract (account_id, bank_id, bank_contract_id)
	select aba.account_id, aba.bank_id, aba.bank_contract_id
	from aba
	join (select top (@bank_id_throttle) bank_id  from aba order by bank_id desc ) limit on limit.bank_id = aba.bank_id

	return;
end
go