use CDS
go
set ansi_nulls on
go
set quoted_identifier on
go
create function dbo.cds_fn_GetBankRegKey(@bank_contract_id int)
	returns varchar(100)
as
begin
	declare @bank_reg_key varchar(100)

	select @bank_reg_key = isnull(b.bank_reg_key, left(c.cust_name, 85) + '_BC_' + cast(@bank_contract_id as varchar(12)))
	from bank_contract bc
	join cust c on c.cust_id = bc.cust_id
	left join bank b on b.bank_id = bc.bank_id
	where bc.bank_contract_id = @bank_contract_id
	return @bank_reg_key


end
go
