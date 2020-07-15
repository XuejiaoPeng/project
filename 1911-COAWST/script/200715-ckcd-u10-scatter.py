import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import xarray as xr
import datetime
import salem

def get_closest_data(var, lat2d, lon2d, lat0, lon0):
    dis_lat2d=lat2d-lat0
    dis_lon2d=lon2d-lon0
    dis=abs(dis_lat2d)+abs(dis_lon2d)
    var=var.where(dis==dis.min(),drop=True).squeeze()
    return var

def windspeed(var1,var2):
    return np.sqrt(var1*var1+var2*var2)



def main():
     
    # constants
    BIGFONT=22
    MIDFONT=18
    SMFONT=16

    cases=["ERA5_C2008_add", "ERA5_TY2001_add", "ERA5_WAOFF_add", "ERA5_WRFROMS_add", "ERA5_WRF_add"]
    line_libs=['b','b-s','r-^','r-v','k']
    wrf_root='/disk/v092.yhuangci/lzhenn/1911-COAWST/'
    
    i_dom=2
    strt_time_str='201809151600'
    end_time_str='201809151900'
    box_R=80


    strt_time_obj=datetime.datetime.strptime(strt_time_str, '%Y%m%d%H%M')
    end_time_obj=datetime.datetime.strptime(end_time_str, '%Y%m%d%H%M')

    
    for (line_type, case) in zip(line_libs, cases):

        # read track data
        tc_info_fn=wrf_root+'/'+case+'/trck.'+case+'.d0'+str(i_dom)
        dateparse = lambda x: pd.datetime.strptime(x, '%Y%m%d%H0000')
        df_tc_info=pd.read_csv(tc_info_fn, sep='\s+', parse_dates=True, index_col='timestamp', header=0, date_parser=dateparse)
        df_tc_info=df_tc_info[((df_tc_info.index>=strt_time_obj)&(df_tc_info.index<=end_time_obj))]
        print(df_tc_info)
       
        # read raw input
        ds = salem.open_wrf_dataset('/disk/v092.yhuangci/lzhenn/1911-COAWST/'+case+'/wrfout_d02')
        ds=ds.sel(time=slice(strt_time_obj,end_time_obj))

        var1 = ds['AKHS'] # heat exch
        var2 = ds['AKMS'] # momentum exch
        var3 = ds['U10'] 
        var4 = ds['V10'] 
       
        exit()

        var1_sta=get_closest_data(var1, var1.lat,var1.lon,bouy_lat0, bouy_lon0)
        var1_sta.plot.line(line_type, linewidth=1, label=case)
        idx_var1=pd.Index(var1_sta.time.values)
        idx_var1=idx_var1.intersection(df_obv.index)
        var1_sta_obv_align=var1_sta.sel(time=idx_var1)
        rmse=((var1_sta_obv_align-df_obv[idx_var1])**2).mean()**.5
        print(rmse.values)

        break

    for index, row in df_bouy_list.iterrows():
        bouy=row['bouy']
        bouy_lat0=row['lat']
        bouy_lon0=row['lon']
        print(bouy)
        dateparse = lambda x: pd.datetime.strptime(x, '%Y-%m-%d %H:%M:%S')
        obv_path=bouy_path+bouy+'.csv'
        df_obv=pd.read_csv(obv_path,parse_dates=True,index_col='采集时间', header=1, date_parser=dateparse)
        # change to HKT, to get bouy data 
        strt_time_hkt_obj=strt_time_obj+ datetime.timedelta(hours=8) 
        end_time_hkt_obj=end_time_obj+ datetime.timedelta(hours=8)
        df_obv_period=df_obv[((df_obv.index>=strt_time_hkt_obj)&(df_obv.index<=end_time_hkt_obj))]
        # change index
        df_obv_period.index = df_obv_period.index - datetime.timedelta(hours=8)
        
        #df_obv_period=df_obv[((df_obv.index>=wrf_time.values[0])&(df_obv.index<=wrf_time.values[-1]))]
        
        #open dataset
        fig,ax = plt.subplots()
        width=15.0
        height=6.0
        #fig,ax = plt.subplots(figsize=(10,4))

        # adjust to fit in the canvas 
        fig.subplots_adjust(left=0.08, bottom=0.18, right=0.99, top=0.92, wspace=None, hspace=None) 
        df_obv=df_obv_period['表层水温℃']

      
        plt.plot(df_obv, label=bouy, linewidth=3, marker='o', color='black')
        plt.legend(loc='best', fontsize=SMFONT)
        plt.xlabel('Time',fontsize=SMFONT)
        plt.ylabel('SST ($\mathregular{^oC}$)',fontsize=SMFONT)
        plt.xticks(fontsize=SMFONT,rotation=-30)
        plt.yticks(fontsize=SMFONT)
        
       # pletp(ax.get_xticklabels(), rotation=-60, ha="right",
       # rotation_mode="anchor")
        plt.title(bouy+' SST', fontsize=BIGFONT)
    #    fig.tight_layout()
    #    plt.show()
        fig.set_size_inches(width, height)
        fig.savefig('../fig/SST_'+bouy+'.pdf')

        #break
if __name__ == "__main__":
    main()

