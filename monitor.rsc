# Clients monitoring script
# Script uses ideas by rextended drPioneer
# https://github.com/drpioneer/MikrotikClientsMonitoring/blob/main/monitor.rsc
# https://forummikrotik.ru/viewtopic.php?p=95497
# tested on ROS 6.49.17 & 7.16.1
# updated 2024/12/13

:local timeThreshold 21;                                                          # threshold time in minutes to out of zone device
:local customList {
  {name="EBreHuu"; mac="00:00:00:00:00:00"};
  {name="rAJluHa"; mac="00:00:00:00:00:00"};
  {name="AHDpeu"; mac="00:00:00:00:00:00"};
  {name="Erop"; mac="00:00:00:00:00:00"};
  {name="DaHuuJl"; mac="00:00:00:00:00:00"};
  {name="DMuTpuu"; mac="00:00:00:00:00:00"};
  {name="AJleKcaHDp"; mac="00:00:00:00:00:00"};
  {name="TaTbRHa"; mac="00:00:00:00:00:00"}};                                     # custom clients list

:global clients; :if ([:len $clients]=0) do={:set clients {name=[toarray ""];mac=[toarray ""];time=[toarray 0];msg=[toarray false]}}
:local Name do={                                                                  # client name detection function
  :global customList; :local name ""
  :foreach client in=$customList do={
    :if (($client->"mac")=$1) do={:set name ($client->"name"); :if ($client->"ignor") do={:return ""}}}
  /ip dhcp-server lease
  :if ([:len $name]=0) do={:set name [get [find mac-address=$1 status="bound"] comment]}
  :if ([:len $name]=0) do={:set name [get [find mac-address=$1 status="bound"] host-name]}
  :if ([:len $name]=0) do={:set name $1}
  :return $name};                                                                 # return client's name from list of dhcp-leases

# time translation function to UNIX time # https://forum.mikrotik.com/viewtopic.php?t=75555#p994849
:local T2U do={ # $1-date/time in any format: "hh:mm:ss","mmm/dd hh:mm:ss","mmm/dd/yyyy hh:mm:ss","yyyy-mm-dd hh:mm:ss","mm-dd hh:mm:ss"
  :local dTime [:tostr $1]; :local yesterDay false; /system clock
  :local cYear [get date]; :if ($cYear~"....-..-..") do={:set cYear [:pick $cYear 0 4]} else={:set cYear [:pick $cYear 7 11]}
  :if ([:len $dTime]=10 or [:len $dTime]=11) do={:set dTime "$dTime 00:00:00"}
  :if ([:len $dTime]=15) do={:set dTime "$[:pick $dTime 0 6]/$cYear $[:pick $dTime 7 15]"}
  :if ([:len $dTime]=14) do={:set dTime "$cYear-$[:pick $dTime 0 5] $[:pick $dTime 6 14]"}
  :if ([:len $dTime]=8) do={:if ([:totime $1]>[get time]) do={:set yesterDay true}; :set dTime "$[get date] $dTime"}
  :if ([:tostr $1]="") do={:set dTime ("$[get date] $[get time]")}
  :local vDate [:pick $dTime 0 [:find $dTime " " -1]]; :local vTime [:pick $dTime ([:find $dTime " " -1]+1) [:len $dTime]]
  :local vGmt [get gmt-offset]; :if ($vGmt>0x7FFFFFFF) do={:set vGmt ($vGmt-0x100000000)}; :if ($vGmt<0) do={:set vGmt ($vGmt*-1)}
  :local arrMn [:toarray "0,0,31,59,90,120,151,181,212,243,273,304,334"]; :local vdOff [:toarray "0,4,5,7,8,10"]
  :local month [:tonum [:pick $vDate ($vdOff->2) ($vdOff->3)]]
  :if ($vDate~".../../....") do={
    :set vdOff [:toarray "7,11,1,3,4,6"]
    :set month ([:find "xxanebarprayunulugepctovecANEBARPRAYUNULUGEPCTOVEC" [:pick $vDate ($vdOff->2) ($vdOff->3)] -1]/2)
    :if ($month>12) do={:set month ($month-12)}}
  :local year [:pick $vDate ($vdOff->0) ($vdOff->1)]
  :if ((($year-1968)%4)=0) do={:set ($arrMn->1) -1; :set ($arrMn->2) 30}
  :local toTd ((($year-1970)*365)+(($year-1968)>>2)+($arrMn->$month)+([:pick $vDate ($vdOff->4) ($vdOff->5)]-1))
  :if ($yesterDay) do={:set toTd ($toTd-1)};   # bypassing ROS6.xx time format problem after 00:00:00
  :return (((((($toTd*24)+[:pick $vTime 0 2])*60)+[:pick $vTime 3 5])*60)+[:pick $vTime 6 8]-$vGmt)}

# time conversion function from UNIX time # https://forum.mikrotik.com/viewtopic.php?p=977170#p977170
:local U2T do={ # $1-UnixTime $2-OnlyTime
  :local ZeroFill do={:return [:pick (100+$1) 1 3]}
  :local prMntDays [:toarray "0,0,31,59,90,120,151,181,212,243,273,304,334"]
  :local vGmt [:tonum [/system clock get gmt-offset]]
  :if ($vGmt>0x7FFFFFFF) do={:set vGmt ($vGmt-0x100000000)}
  :if ($vGmt<0) do={:set vGmt ($vGmt*-1)}
  :local tzEpoch ($vGmt+[:tonum $1])
  :if ($tzEpoch<0) do={:set tzEpoch 0}; # unsupported negative unix epoch
  :local yearStamp (1970+($tzEpoch/31536000))
  :local tmpLeap (($yearStamp-1968)>>2)
  :if ((($yearStamp-1968)%4)=0) do={:set ($prMntDays->1) -1; :set ($prMntDays->2) 30}
  :local tmpSec ($tzEpoch%31536000)
  :local tmpDays (($tmpSec/86400)-$tmpLeap)
  :if ($tmpSec<(86400*$tmpLeap) && (($yearStamp-1968)%4)=0) do={
    :set tmpLeap ($tmpLeap-1); :set ($prMntDays->1) 0; :set ($prMntDays->2) 31; :set tmpDays ($tmpDays+1)}
  :if ($tmpSec<(86400*$tmpLeap)) do={:set yearStamp ($yearStamp-1); :set tmpDays ($tmpDays+365)}
  :local mnthStamp 12; :while (($prMntDays->$mnthStamp)>$tmpDays) do={:set mnthStamp ($mnthStamp-1)}
  :local dayStamp [$ZeroFill (($tmpDays+1)-($prMntDays->$mnthStamp))]
  :local timeStamp (00:00:00+[:totime ($tmpSec%86400)])
  :if ([:len $2]=0) do={:return "$yearStamp/$[$ZeroFill $mnthStamp]/$[$ZeroFill $dayStamp] $timeStamp"} else={:return "$timeStamp"}}

# main body
:local idDev [/system identity get name]
:set timeThreshold ($timeThreshold*60)
/ip dhcp-server lease
:foreach dhcpLse in=[find status="bound"] do={
  :local findMac [get $dhcpLse mac-address]
  :local name ""; :local ignor false
  :foreach client in=$customList do={
    :if (($client->"mac")=$findMac) do={:set name ($client->"name"); :if ($client->"ignor") do={:set ignor true}}}
  :if (!$ignor) do={
    :if ([:len $name]=0) do={:set name [get $dhcpLse comment]}
    :if ([:len $name]=0) do={:set name [get $dhcpLse host-name]}
    :if ([:len $name]=0) do={:set name "NoName $findMac"}
    :local hostMac ""; :do {:set hostMac [/interface bridge host get [find mac-address=$findMac] mac-address]} on-error={}
    :local stringMsg ""; :local index; :set index [:find ($clients->"mac") $findMac]
    :if ([:len $index]=0) do={                                                    # when client is not presented in base of clients ->
      :set index ([:len ($clients->"mac")]);                                      # last index for new client in base
      :set ($clients->"mac" ->$index) $findMac
      :set ($clients->"name"->$index) $name
      :if ($hostMac~"([0-9A-F]{2}[:]){5}[0-9A-F]{2}") do={                        # when client is presented in bridge hosts ->
        :set ($clients->"time"->$index) [$T2U];                                   # time of set status 'near'
        :set ($clients->"msg"->$index) true;                                      # message 'near' is sent
        :set stringMsg ">+ $($clients->"name"->$index) OKOJlO '$idDev' +<";       # client is 'near'
        /log warning $stringMsg
      } else={                                                                    # when client is not presented in bridge hosts ->
        :set ($clients->"time"->$index) (-[$T2U]);                                # time of set status 'out of zone'
        :set ($clients->"msg"->$index) false;                                     # message 'out of zone' is sent
        :set stringMsg ">- $($clients->"name"->$index) BHE 3OHbl '$idDev' -<";    # client is 'out of zone'
        /log warning $stringMsg}
    } else={                                                                      # when client is presented in base of clients ->
      :set ($clients->"name"->$index) $name
      :if ($hostMac~"([0-9A-F]{2}[:]){5}[0-9A-F]{2}") do={                        # when client is presented in bridge hosts ->  
        :if (($clients->"time"->$index)<0) do={                                   # when client has status 'out of zone' ->
          :set ($clients->"time"->$index) [$T2U]};                                # time of set status 'near'
      } else={                                                                    # when client is not presented in bridge hosts ->
        :if (($clients->"time"->$index)>0) do={                                   # when client has status 'near' ->
          :set ($clients->"time"->$index) (-[$T2U])}};                            # time of set status 'out of zone'
      :if (($clients->"time"->$index)<0) do={                                     # when client has status 'out of zone' ->
        :if ($clients->"msg"->$index) do={                                        # when message 'out of zone' was not sent ->
          :if ((-($clients->"time"->$index)+$timeThreshold)<[$T2U]) do={          # when status 'out of zone' more threshold time ->
            :set ($clients->"msg"->$index) false;                                 # message 'out of zone' is sent
            :set stringMsg "-- $($clients->"name"->$index) BHE 3OHbl '$idDev' c $[$U2T (-($clients->"time"->$index)) "time"] --"; # client is 'out of zone'
            /log warning $stringMsg}}}
      :if (($clients->"time"->$index)>0) do={                                     # when client has status 'near' ->
        :if (!($clients->"msg"->$index)) do={                                     # when message 'near' was not sent -> 
          :set ($clients->"msg"->$index) true;                                    # message 'near' is sent
          :set stringMsg "++ $($clients->"name"->$index) OKOJlO '$idDev' ++";     # client is 'near'
          /log warning $stringMsg}}}
    :if (($clients->"time"->$index)>0) do={:set stringMsg "++ $($clients->"name"->$index) OKOJlO '$idDev' ++"; :put $stringMsg}
    :if (($clients->"time"->$index)<0) do={:set stringMsg "-- $($clients->"name"->$index) BHE 3OHbl '$idDev' --"; :put $stringMsg}
}}
