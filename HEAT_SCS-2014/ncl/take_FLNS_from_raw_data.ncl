

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
    case_name="HEATCTRL"
    exedir="ctrl_mon"
    period="0001-0030"
    pdata_fn="../post_data/"+case_name+".FLNS.mon."+period+".nc"

; ==============================================================
; Open the file: Read only the user specified period
; ==============================================================
	all_files = systemfunc ("ls ../"+case_name+"/"+exedir+"/*cam.h0.00[0-3]*"); ../"+case_name+"/"+exedir+"/*cam.h0.002[0-4]*")
	setfileoption("nc","SuppressClose",False) ; close too many files
	
	ctrl_in      = addfiles (all_files, "r")   ; note the "s" of addfile
	
	ListSetType (ctrl_in, "cat")             ; concatenate or "merge" (default)
    ctrl_var = ctrl_in[:]->FLNS
    printVarSummary(ctrl_var)

	system("rm "+pdata_fn)
	ncdf = addfile(pdata_fn ,"c")  ; open output netCDF file
	; output variables directly
	ncdf->FLNS=ctrl_var
end
