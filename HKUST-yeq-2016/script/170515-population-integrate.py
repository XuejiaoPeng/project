#!/usr/bin/python
# -*- coding: UTF-8 -*-
#
#
#       L_Zealot
#       May 1, 2017
#
#
import scipy.io as sio 
from netCDF4 import Dataset
import numpy as np
import json
import datetime
import time

# Time settings
start_time='2015-01-01 00:00:00'
end_time='2015-01-31 00:00:00'

# Integration step in Hour
int_step=24

# Number of points
npoints=16720

# Operation
int_time_obj = datetime.datetime.strptime(start_time, '%Y-%m-%d %H:%M:%S')
end_time_obj = datetime.datetime.strptime(end_time, '%Y-%m-%d %H:%M:%S')
time_delta=datetime.timedelta(hours=int_step)

# parser path


def read_latlon(pfname):
    corfile= Dataset(pfname)
    lat=corfile.variables['LAT'][0,0,:,:]
    lon=corfile.variables['LON'][0,0,:,:]
    return lat, lon

# Get gridsystem
pfname='/home/yangsong3/L_Zealot/data-mirror/data-model/L_Zealot/HKUST_yeq-2016/gridsys/GRIDCRO2D_3km'
lat_mtx, lon_mtx = read_latlon(pfname)

# Get population
mat_contents=sio.loadmat('../data/obv/population_output_D3.mat')
pop=mat_contents['population_output'] #list
pop_array=np.array(pop)
pop_array=pop_array.transpose()

pt_dic={}
fr = open('/home/yangsong3/L_Zealot/data-mirror/data-model/L_Zealot/HKUST_yeq-2016/resident-time_output/data/hysplit/prd/point-3km-xy-grid', 'r')
point_list=fr.readlines()

for idx, point in enumerate(point_list):
    content=point.split()       # [1]--cor_x [2]--cor_y [3]--lat [4]--lon
    pt_id =idx+1
    pt_dic[str(pt_id)]={'cor_x':int(content[1]), 'cor_y':int(content[2]), 'lat':float(content[3]), 'lon':float(content[4]), 'exposure': 0}

while int_time_obj <= end_time_obj:
    inv_path='/home/yangsong3/data-model/L_Zealot/HKUST_yeq-2016/resident-time_output/data/hysplit/prd/population/traj_record/'+int_time_obj.strftime('%m')+'/'
    print('parsing '+int_time_obj.strftime('%y%m%d%H')+'...')
    fn='forward_'+int_time_obj.strftime('%y%m%d%H')
    fr = open(inv_path+fn, 'r')
    lines=fr.readlines()
    lines0=lines[16724:] 
    len_line0=len(lines0)

    # Loop the record
    strt_time=time.clock()
    for pos_line, point in enumerate(lines0):
        content=point.split() # [0]--# [9]--lat [10]--lon
        pt_id=str(content[0])
        
        lat=float(content[9])     # traj position
        lon=float(content[10])
        
        # initial min distance threshold to the grid point
        min_dis=0.04

        cor_x_range=np.argwhere(abs(lat_mtx[:,152/2]-lat)<min_dis)
        cor_y_range=np.argwhere(abs(lon_mtx[110/2,:]-lon)<min_dis)
        for cor_x_pos in cor_x_range:
            for cor_y_pos in cor_y_range:
                dislat=abs(lat_mtx[cor_x_pos, cor_y_pos]-lat)
                dislon=abs(lon_mtx[cor_x_pos, cor_y_pos]-lon)
                if (dislat+dislon<min_dis):
                    min_dis=dislat+dislon
                    cor_x_pos0=cor_x_pos
                    cor_y_pos0=cor_y_pos
        if pos_line % 1000==0:
            elapsed=time.clock()-strt_time
            print('Line %10d/%10d Time elapsed:%7.3fs Min_Dis=%5.3f' % (pos_line, len_line0, elapsed, min_dis))

        pt_dic[pt_id]['exposure']=pt_dic[pt_id]['exposure']+pop_array[cor_x_pos0, cor_y_pos0]
    for idx in pt_dic:
        pt_dic[idx]['exposure']=pt_dic[idx]['exposure']/12.0 # adjust the exposure unit to pop*hr


    # output
    fr2=open(inv_path+'../../exposure/exp_'+int_time_obj.strftime('%y%m%d%H')+'.txt','w')
    for item in pt_dic.values():
        cor_x=item['cor_x']
        cor_y=item['cor_y']
        lat=item['lat']
        lon=item['lon']
        value=item['exposure']
        fr2.write('%4d %4d %8.3f %8.3f %7d\n' % (cor_x, cor_y, lat, lon, value))
    fr2.close()
    for idx in pt_dic:
        pt_dic[idx]['value']=0

    int_time_obj = int_time_obj+time_delta
# While: All experiments


