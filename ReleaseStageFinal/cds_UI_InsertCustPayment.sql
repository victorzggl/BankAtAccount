use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[cds_UI_InsertCustPayment] @cust_id int, @cust_payment_type_id int, @payment_date datetime = null, @payment_amount decimal(18,2), @settlement_date date = null, @tran_num varchar(100) = null, @cds_user_id int, @bank_contract_id int
as 

--exec cds_UI_InsertCustPayment @cust_id = 0, @cust_payment_type_id = 2, @payment_date = '2019-02-19', @payment_amount = 100, @settlement_date = null, @tran_num = 'ABC123456789', @cds_user_id = 0

declare @inserted_by varchar(100) = (select login_name from cds_user where cds_user_id = @cds_user_id),
		@cust_payment_type varchar(50) = (select code from cust_payment_type where cust_payment_type_id = @cust_payment_type_id),
		@cust_payment_id int,
		@error varchar(500) = '',
		@ReleaseVersion varchar(100) = 'BETA'

if @inserted_by is null
	set @error += 'CDS user is invalid or missing; '

if @cust_payment_type = 'TV_TAX_WRITE_OFF' and isnull(@payment_amount,0) <> 9
	set @error += N'TV Tax Write-Off must be €9; '

if @bank_contract_id is null
	set @error += '; active bank contract is required'

if @error = ''
begin
	exec cds_InsertCustPayment @cust_id = @cust_id, @cust_payment_type_id = @cust_payment_type_id, @payment_date = @payment_date, @payment_amount = @payment_amount, @settlement_date = @settlement_date, @tran_num = @tran_num, @inserted_by = @inserted_by, @cust_payment_id = @cust_payment_id output, @error = @error output, @bank_contract_id = @bank_contract_id
end

select @cust_payment_id [cust_payment_id], nullif(@error,'') [error_message]
go

