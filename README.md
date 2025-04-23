# Technical support to Geographical Society of Myanmar (GSM)
As part of the post-disaster response activity by The Spirit of Brotherhood Mission (TSBM), its sister organization (GSM) attempted to conduct field observation at most affected areas. I provided technical support to identify priority zones for field observation using damage proxy map from Remote Sensing Lab at Earth Observatory Singapore (EOS-RS). Secondly, the location of the ground feature is extracted from EXIF data of drone shots, taken by Real-Time Kinematic (RTK) correction enabled DJI M30T, and calculate the ground seperation to inform accuracy. 

## 1. Data extraction
Following data are extracted
| Name | Description |
| ---- | ---- |
| EOS-RS_20250405_DPM_S1_Myanmar_Earthquakes_v0.9.tif | Damage Proxy Map: Myanmar, Earthquakes, 5 Apr 2025, v0.9 from [EOS-RS](https://eos-rs-products.earthobservatory.sg/EOS-RS_202503_Myanmar_Earthquakes)|
| rupture.json | Fault rupture from [USGS](https://earthquake.usgs.gov/earthquakes/eventpage/us7000pn9s/shakemap/metadata)|
| *.jpg | Photos produced by DJI M30T from [TSBM](https://www.facebook.com/people/TSBM-The-Spirit-of-Brotherhood-Mission/100067464211453) |

## 2. Analysis workflow
### 2.1 Identifying the priority zones for field observation
Damage Proxy Map from EOS-RS is used to identify the areas (30m x 30m pixel) with severe damage. Then, those severely damage pixels are counted in each 25sqKm grid, which GSM believed to be a manageably small and efficiently large to conduct field visits. Finally, 25sqKm grids which contain more than average count of severely damage pixels are identified as 'priority zones' for field observation. <br/>
<img src=https://github.com/user-attachments/assets/e48e34f9-c345-43b7-8d67-9d38daaf91dd title="workflow_priority_zones" width="400"> 

### 2.2 Informing location of damage
GSM use DJI M30T to record the ground features duirng field observation. Level of damage and accuracy of the location of the features are important consideration during ground validation of damage proxy map. So, I extracted EXIF data from photo using 'exifr' package and calculate ground seperation using 'geosphere' package in R. Location of subject is available from laser range finder of the drone, and photo with both oblique and nadir views used.

## 3. Results
### 3.1 Priority zones
There are total of 246 priority zones around the fault line, where surface damage are expected to be obvious according to the Damage Proxy Map (v0.9) from EOS-RS. Interactive map can be seen [here!](https://www.google.com/maps/d/u/0/edit?mid=1FUmVraAmTzFeiJu0LVaY_sLRaEWCJwo&ll=20.676505293372237%2C96.4612044193668&&z=9). <br/>
<img src=https://github.com/user-attachments/assets/c1b0b2f7-9bb1-4865-81bd-6d7979a8ba49 title="priority_zones" width="500"> 

### 3.2 Location accuracy
According to the metadata from the footage, the location is determined by DJI's RTK corrections. RTK flag value is 16, which means that RTK was enabled while taking the photo and correction was done by single point location (as there is no base station). The RTK standard deviation for both latitude and longitude are around 2-2.5 meter and accuracy was not good. <br/> 
EXIF data from the drone footage (nadir view): <br/>
<img src=https://github.com/user-attachments/assets/96069e3c-ac88-4bef-9d18-5f6390953ef4 title="nd_cam" width="500"> 
<br> The calculated ground seperation is observed as below: <br/>
<img src=https://github.com/user-attachments/assets/0adc73d2-676a-4c8d-9f21-335d96411cf9 title="ground_seperation" width="500"> 
<br>*Where:* <br/>
*lrfnd = Target location by Laser Range Finder in nadir view* <br/>
*lrfob = Target location by Laser Range Finder in oblique view* <br/>
*ndcam = Camera location in nadir view* <br/>
*ge = Point location of subject in Google Earth*

