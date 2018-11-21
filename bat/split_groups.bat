@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
rem this script will split out the different groups
set inputfile=L11500_RX_EXTRACT-20181108.TXT
set prefix=L11500_RX_EXTRACT-20181108

rem WHY DID THEY HAVE TO USE A CARET AS THE DELIMITER?!?!?!
for %%I in (^^000000^^ ^^999991^^ ^^999992^^ ^^999993^^ ^^999994^^ ^^999995^^) do (
	echo %%I
	IF "%%I"=="^000000^" (
		echo FFS
		set filename=%prefix%_000000.txt
		echo clq_claim_status^^clq_claim_mod^^clq_payment_date^^planpaydate^^payerid^^clq_transaction_type^^CLRX_RX_Date^^clc_service_from_date^^clc_service_to_date^^clc_procedure_code^^CLRX_Days_Supply^^CLRX_Quantity^^CLRX_Co_Pay^^clq_payment^^clq_plan_paid_amt^^TNewNum^^CLRX_Ingredient_Price^^CLRX_Disp_Fee^^NPIBILL^^CLC_Precert_PA_Number^^NPIRX^^clc_claim_icn^^salestax^^lpc_pa_ind^^ > !filename!
		findstr /C:"^000000^" %inputfile% >> !filename!
	) ELSE IF "%%I"=="^999991^" (
		echo 999991
		set filename=%prefix%_999991.txt
		echo clq_claim_status^^clq_claim_mod^^clq_payment_date^^planpaydate^^payerid^^clq_transaction_type^^CLRX_RX_Date^^clc_service_from_date^^clc_service_to_date^^clc_procedure_code^^CLRX_Days_Supply^^CLRX_Quantity^^CLRX_Co_Pay^^clq_payment^^clq_plan_paid_amt^^TNewNum^^CLRX_Ingredient_Price^^CLRX_Disp_Fee^^NPIBILL^^CLC_Precert_PA_Number^^NPIRX^^clc_claim_icn^^salestax^^lpc_pa_ind^^ > !filename!
		findstr /C:"^999991^" %inputfile% >> !filename!
	) ELSE IF "%%I"=="^999992^" (
		echo 999992
		set filename=%prefix%_999992.txt
		echo clq_claim_status^^clq_claim_mod^^clq_payment_date^^planpaydate^^payerid^^clq_transaction_type^^CLRX_RX_Date^^clc_service_from_date^^clc_service_to_date^^clc_procedure_code^^CLRX_Days_Supply^^CLRX_Quantity^^CLRX_Co_Pay^^clq_payment^^clq_plan_paid_amt^^TNewNum^^CLRX_Ingredient_Price^^CLRX_Disp_Fee^^NPIBILL^^CLC_Precert_PA_Number^^NPIRX^^clc_claim_icn^^salestax^^lpc_pa_ind^^ > !filename!
		findstr /C:"^999992^" %inputfile% >> !filename!
	) ELSE IF "%%I"=="^999993^" (
		echo 999993
		set filename=%prefix%_999993.txt
		echo clq_claim_status^^clq_claim_mod^^clq_payment_date^^planpaydate^^payerid^^clq_transaction_type^^CLRX_RX_Date^^clc_service_from_date^^clc_service_to_date^^clc_procedure_code^^CLRX_Days_Supply^^CLRX_Quantity^^CLRX_Co_Pay^^clq_payment^^clq_plan_paid_amt^^TNewNum^^CLRX_Ingredient_Price^^CLRX_Disp_Fee^^NPIBILL^^CLC_Precert_PA_Number^^NPIRX^^clc_claim_icn^^salestax^^lpc_pa_ind^^ > !filename!
		findstr /C:"^999993^" %inputfile% >> !filename!
	) ELSE IF "%%I"=="^999994^" (
		echo 999994
		set filename=%prefix%_999994.txt
		echo clq_claim_status^^clq_claim_mod^^clq_payment_date^^planpaydate^^payerid^^clq_transaction_type^^CLRX_RX_Date^^clc_service_from_date^^clc_service_to_date^^clc_procedure_code^^CLRX_Days_Supply^^CLRX_Quantity^^CLRX_Co_Pay^^clq_payment^^clq_plan_paid_amt^^TNewNum^^CLRX_Ingredient_Price^^CLRX_Disp_Fee^^NPIBILL^^CLC_Precert_PA_Number^^NPIRX^^clc_claim_icn^^salestax^^lpc_pa_ind^^ > !filename!
		findstr /C:"^999994^" %inputfile% >> !filename!
	) ELSE IF "%%I"=="^999995^" (
		echo 999995
		set filename=%prefix%_999995.txt
		echo clq_claim_status^^clq_claim_mod^^clq_payment_date^^planpaydate^^payerid^^clq_transaction_type^^CLRX_RX_Date^^clc_service_from_date^^clc_service_to_date^^clc_procedure_code^^CLRX_Days_Supply^^CLRX_Quantity^^CLRX_Co_Pay^^clq_payment^^clq_plan_paid_amt^^TNewNum^^CLRX_Ingredient_Price^^CLRX_Disp_Fee^^NPIBILL^^CLC_Precert_PA_Number^^NPIRX^^clc_claim_icn^^salestax^^lpc_pa_ind^^ > !filename!
		findstr /C:"^999995^" %inputfile% >> !filename!
	) ELSE (
		REM default case...
	)
)