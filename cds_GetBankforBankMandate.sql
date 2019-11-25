use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter procedure [dbo].[cds_GetBankForBankMandate]
as

-- TODO @PaulP bank_id has been replaced with bank_contract_id
-- 	bank_account_key can return a {mollie cst_key OR null}
-- 		if null new mollie cst_key should be returned,
-- 			if not null only new bank_account_key is needed, return either value to cds_UpdateBankMandate

select bc.bank_contract_id, bc.bank_reg_key, bc.signatory_email [email], bc.bank_account, b.bank_account_key, bc.bank_account_name
from bank b
join bank_contract bc on bc.bank_id = b.bank_id
join cds_fn_GetActiveBankContract (null, null, null) gabc on gabc.bank_contract_id = bc.bank_contract_id
where (b.error is null
	or b.error like 'System.Net.Http.HttpRequestException: An error occurred while sending the request.%'
	or b.error like 'System.Data.Entity.Core.EntityException: An exception has been raised that is likely due to a transient failure.%')
order by bc.bank_contract_id
go

