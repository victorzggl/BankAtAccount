use CDS_Send
go
set ansi_nulls on
go
set quoted_identifier on
go
create function dbo.send_fn_ConvertAccountSendAccountNumToCsv(@cust_send_id int)
	returns varchar(max)
as
begin
	declare @account_num varchar(max)

	select @account_num =  COALESCE(@account_num + ', ', '') + a.account_num
	from cust_send cs
	join account_send acs on acs.cust_send_id = cs.cust_send_id
	join cds.dbo.account a on a.account_id = acs.account_id
	where cs.cust_send_id = @cust_send_id
	and a.account_num is not null

	return @account_num

end
go
