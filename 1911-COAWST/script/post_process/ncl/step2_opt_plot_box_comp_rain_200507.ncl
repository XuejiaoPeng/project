;*******************************************************
; lcnative_2.ncl
;*******************************************************
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
begin
;************************************************
; open file and read in data
;************************************************

; Assign default settings if lack of argument pass
    if (.not. isvar("i_dom")) then 
        i_dom=1
    end if 
    if (.not. isvar("wrfout_path")) then 
        wrfout_path="/users/b145872/project-dir/app/COAWST-sandy-wrf/WRF/run/"
    end if 
    if (.not. isvar("casename")) then 
        casename="mangkhut-wrfonly" 
    end if 
    if (.not. isvar("fig_path")) then 
        wrfout_path="/users/b145872/project-dir/app/COAWST-sandy-wrf/WRF/run/"
    end if 
    if (.not. isvar("trck_path")) then 
        trck_path="/disk/v092.yhuangci/lzhenn/1911-COAWST/cma.trck.mangkhut"
    end if 


    print(">>STEP02(opt): Composite "+casename+" in following boxes...") 
    fig_prefix="d0"+tostring(i_dom)+"_precip_"
    g_font=0.02
    month_abbr = (/"","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep", \
                         "Oct","Nov","Dec"/)
    
    ; get in ibtrck data
    ncol=6
    tc_loc = readAsciiTable(trck_path,ncol,"float", 1) ; tc_loc(nrec, ncol) 
    dims=dimsizes(tc_loc) 
    dim_tc=dims(0)
 

   
   ; get wrf nc data
    wrfout_fn=wrfout_path+"/wrfout_d0"+tostring(i_dom)
    ctrl_in      = addfile (wrfout_fn, "r")   ; note the "s" of addfile
    
    ; parser time
    time0 = wrf_user_getvar(ctrl_in,"Times", -1)
    xtime = wrf_times_c( time0, 1 ) 
    ;xtime = xtime+8 
    lc_date=cd_calendar(xtime, 0)
    year   = tointeger(lc_date(:,0))    ; Convert to integer for
    month  = tointeger(lc_date(:,1))    ; use sprinti 
    day    = tointeger(lc_date(:,2))
    hour   = tointeger(lc_date(:,3))
    minute = tointeger(lc_date(:,4))
    second = lc_date(:,5)

    date_str = month_abbr(month)+sprinti(" %0.2i ", day) + sprinti("%0.2iZ", hour) +sprinti("%0.2i:00", minute)
    lentime=dimsizes(xtime)
   
    ; get in wrf tc track data
    ;0-timestamp 1-lat 2-lon 3-minSLP 4-maxWS 5-uRadius 6-vRadius
    case_tc = asciiread(wrfout_path+"/trck."+casename+".d0"+i_dom,(/lentime,7/),"float")
    ; parser lat lon
    lat2d = wrf_user_getvar(ctrl_in,"XLAT",  0)
    lon2d = wrf_user_getvar(ctrl_in,"XLONG", 0)
  

    ; get rain
    ;ctrl_var1  = wrf_user_getvar(ctrl_in,"RAINC", -1)  
    ctrl_var1  = wrf_user_getvar(ctrl_in,"RAINNC", -1)  
    ;ctrl_var1  = (ctrl_var1+ctrl_var2)
 
    dims:=dimsizes(ctrl_var1)
    dim_t=dims(0)
    dim_y=dims(1)
    dim_x=dims(2)
    
    ctrl_var1(1:lentime-1,:,:)=ctrl_var1(1:lentime-1,:,:)-ctrl_var1(0:lentime-2,:,:)

    ; parser lat lon
    lat2d = wrf_user_getvar(ctrl_in,"XLAT",  1)
    lon2d = wrf_user_getvar(ctrl_in,"XLONG", 1)
    ctrl_var1@lat2d = lat2d
    ctrl_var1@lon2d = lon2d
    ;ctrl_var1=(/ctrl_var1-273.15/)   
    ctrl_var1(0,0,:)=(/ctrl_var1(0,0,:)+1e-2/)

   

res                   = True              ; plot mods desired
;---Resources for filled contour plot
  
  res@cnLevelSelectionMode = "ExplicitLevels"   ; set manual contour levels
  res@cnLevels =    (/0.1, 0.5, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 25, 30, 40, 50/)
   
  res@gsnMaximize          = True
  res@gsnFrame = False
  res@gsnDraw = False
  res@cnFillOn             = True  
  res@cnLinesOn            = False
  res@cnLevelSpacingF      = 2.           ; NCL chose 4.0
  res@lbOrientation        = "Vertical"

;---Necessary for contours to be overlaid correctly on WRF projection
  res@tfDoNDCOverlay       = True
  res@gsnAddCyclic         = False
  res@cnFillMode           = "CellFill" ; Raster Mode
  res@gsnSpreadColors      = True               ; use full color map
  res@gsnRightString = "mm/hr"
  res@gsnStringFontHeightF = g_font 
  res@gsnMaximize      = True       ; fill up the page
  res@gsnPaperOrientation = "portrait"

  res@lbLabelBarOn = True   ; turn off the label bar
  res@lbOrientation          = "vertical"
  res@lbLabelFontHeightF  = 0.02              ; make labels smaller
  res@tmYLMajorLengthF = 0.01
  res@tmXBMajorLengthF = 0.01
  res@lbLabelStride = 2  
  res@tmXBLabelFontHeightF = g_font
  res@tmYLLabelFontHeightF = g_font
  res@mpGridAndLimbOn        = True             ; Turn on lat/lon grid
  res@mpGridLineDashPattern  = 2                ; Dashed lines
  res@mpGridSpacingF         = 5.0 
  res@mpGridLineThicknessF   = 2.0
  res@mpGridLineColor        = "Gray80"

  res@mpOutlineOn             = True  ; Use outlines from shapefile
  res@mpGeophysicalLineColor = "gray10"
  res@cnFillDrawOrder         = "PreDraw"
  res@mpDataBaseVersion       = "MediumRes"
  res@mpDataSetName           = "Earth..4"
  res@mpAreaMaskingOn         = True
  res@mpMaskAreaSpecifiers    = (/"China","Taiwan","Disputed area between India and China","India:Arunachal Pradesh"/)
  res@mpLandFillColor         = "white"
  res@mpInlandWaterFillColor  = "white"
  wks_type="png"
  wks_type@wkWidth=800
  wks_type@wkHeight=800

; tc box radius
boxR=80

var_comp=ctrl_var1(0,0:2*boxR,0:2*boxR)
var_comp=0
lentime=37
time_frame=27
print(date_str(time_frame))
print(date_str(lentime))
do while(time_frame .lt. lentime)
    ;---Set map resources based on projection on WRF output file

    ;************************************************
    ; create plot
    ;************************************************
    
    wks = gsn_open_wks(wks_type,fig_path+"/"+fig_prefix+casename+"_box_comp")      ; send graphics to PNG file
    
  
    gsn_define_colormap(wks,"precip2_17lev")
    res@gsnLeftString=casename+" Comp Hourly Pr"
    ;---Call plotting routine which draws contours over a map
    tc_lon=case_tc(time_frame,2)
    tc_lat=case_tc(time_frame,1)
     
    point=getind_latlon2d(lat2d,lon2d,tc_lat,tc_lon)
    cor_x1=point(0,0)
    cor_y1=point(0,1)
    ; (0,0)->(0,1)->(1,1)->(1,0)        
    ;box_x=(/cor_x1-boxR, cor_x1-boxR, cor_x1+boxR, cor_x1+boxR, cor_x1-boxR/)
    ;box_y=(/cor_y1-boxR, cor_y1+boxR, cor_y1+boxR, cor_y1-boxR, cor_y1-boxR/)
    var_comp=var_comp+ctrl_var1(time_frame,cor_x1-boxR:cor_x1+boxR,cor_y1-boxR:cor_y1+boxR)
    time_frame=time_frame+1
end do
var_comp=var_comp/(lentime-27+1)
res@cnLevelSelectionMode = "ExplicitLevels"   ; set manual contour levels
res@cnLevels =    (/0.1, 0.5, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 25, 30, 40, 50/)
plot = gsn_csm_contour(wks,var_comp,res)
draw(plot)
frame(wks)
 
end
