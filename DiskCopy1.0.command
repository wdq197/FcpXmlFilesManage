#!/bin/bash
# Copyright (c) [2024-2030] [WangGuoqi]
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# Version: 1.0.0
# Last modified: 2024-05-07
# Author: WangGuoQi
# Description: 
# 把xml文件放入这个文档一起的目录中，双击这个文档则可以拷贝xml文档中关联的文件 
Version=1.0
FullPath="$0"
ThisPath="${FullPath%[/]*}"
#cd "$ThisPath"
ThisPath=$(cd `dirname $FullPath`; pwd)
basedir=`cd $(dirname $0); pwd -P`
cd "$ThisPath"
echo "当前的软件版本为${Version}"
echo "当前目录为：`pwd`"
echo -e "当前目录下文件有：\n"
ls -l
Force_Copy_Flag=0
Only_Volume_Calculate_Flag=0
#Only_CopyAudioFiles_Flag=0
FatherDisk_To_Disk_Flag=1
Dest_Path_Input=""
CoreFileProcess=".FileManage1.0.sh"
disk_copy_check_input_params() {
  local -a space_params=() # 初始化一个数组来存储包含空格的参数
  local -a slash_params=() # 初始化一个数组来存储包含斜杠的参数
  local -a colon_params=()  # 包含冒号的参数

  # 遍历所有输入参数
  for arg in "$@"; do
    if [[ "$arg" == *" "* ]]; then
      space_params+=("$arg")
    elif [[ "$arg" == *"/"* ]]; then
      slash_params+=("$arg")
    elif [[ "$arg" == *":"* ]]; then
      colon_params+=("$arg")
    fi
  done

  # 检查是否找到了包含空格或斜杠的参数
  if [ ${#space_params[@]} -ne 0 ]; then
    # 输出所有包含空格的参数
    #echo "以下文件名包含空格："
    for param in "${space_params[@]}"; do
      echo "$param:文件名包含空格"
    done
  fi

  if [ ${#slash_params[@]} -ne 0 ]; then
    # 输出所有包含斜杠的参数
    #echo "以下文件名包含斜杠："
    for param in "${slash_params[@]}"; do
      echo "$param:文件名包含斜杠"
    done
  fi

  if [ ${#colon_params[@]} -ne 0 ]; then
    #echo "以下输入参数包含冒号："
    for param in "${colon_params[@]}"; do
        printf "%s" "${param//://}"
        echo ":文件名包含斜杠"
    done
  fi
  # 如果找到了包含空格或斜杠的参数，则执行退出前删除操作
  if [ ${#space_params[@]} -ne 0 ] || [ ${#slash_params[@]} -ne 0 ] || [ ${#colon_params[@]} -ne 0 ]; then
    #echo "所有输入参数都不能包含斜杠或空格，请检查后重新输入"
    return 1
  else
    
    # 脚本可以继续执行其他操作
    # ...
    return 0
  fi
}

touch ~/${CoreFileProcess}
cat > ~/${CoreFileProcess}<< "EOF"
#!/bin/bash
# Copyright (c) [2024-2030] [WangGuoqi]
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# Version: 1.0.0
# Last modified: 2024-05-07
# Author: WangGuoQi
# Description: 
# 本文档，可轻松通过xml文档将主盘的素材分集拷贝到另外同名的盘中，要求xml文档必须能够连接源盘中的文件
# 需要传递7个参数 
# 第一个参数 f or n  f表示强制覆盖已经存在的文件 n 表示跳过已经存在的文件
# 第二个参数 yes or no yes表示需要暂停确认列表中的文件，no表示相反的意思
# 第三个参数 uc or c 是否仅仅计算大小，c表示仅仅计算文件大小，uc表示不仅仅计算大小
# 第四个参数 是否仅拷贝音频 audio all
# 第五个参数 是否硬盘对硬盘拷贝
# 第六个参数 为目标硬盘名称
# 第七个参数为需要拷贝的文件的fcp7的Xml文件
# FileManage n|f no|yes uc|c all|audio dd|ndd "JZDSBC"  test.xml
# 如果第一个参数是 del 则进入删除模式，删除模式的分割符是 except
# 如果没有 except 的话，会整合所有的 xml 文件将其对应的内容删除
# 如果有 except 的话会只删除except 前边的 xml 中对应的文件
# FileManage del *.xml *.xml except x.xml x.xml
# 把用到外部文档的部分都用变量来代替
Version=2.0.0
FullPath="$0"
ThisPath="${FullPath%[/]*}"
#cd "$ThisPath"
ThisPath=$(cd `dirname $FullPath`; pwd)
basedir=`cd $(dirname $0); pwd -P`
#cd "$ThisPath"
clear
echo "当前的软件版本为${Version}"
SkipVolumes=0
SuccessCopyVolumes=0
SkipNum=0
SuccessCopyNum=0
SkipedList=SkipedList_${RANDOM}.txt
CopyedList=CopyedList_${RANDOM}.txt

#准备工作文件夹
WorkPath=~/.FasterXMLFilesAbstract
if [[ -d "${WorkPath}" ]];then
:
else
mkdir -p "${WorkPath}"
fi
#echo 清理
#清理临时工作文件夹
rm -rf ~/.FasterXMLFilesAbstract/*
ChildrenDir=""${WorkPath}"/`date +%Y%m%d%H%M%S`_${RANDOM}临时文件夹"
mkdir -p ${ChildrenDir}

#echo "当前目录为：`pwd`"
#echo "当前目录下文件有"
#ls -l
#定义函数
#计算文件大小的定义函数,以MB KB GB 等合适的形式显示
exit_delete_all(){
    rm -rf "${ChildrenDir}"
    exit 0
    
}

check_input_params() {
  local -a space_params=()  # 包含空格的参数
  local -a slash_params=()  # 包含斜杠的参数
  local -a colon_params=()  # 包含冒号的参数

  # 遍历所有输入参数
  for arg in "$@"; do
    if [[ "$arg" == *" "* ]]; then
      space_params+=("$arg")
    elif [[ "$arg" == *"/"* ]]; then
      slash_params+=("$arg")
    elif [[ "$arg" == *":"* ]]; then
      colon_params+=("$arg")
    fi
  done

  # 检查是否找到了包含空格、斜杠或冒号的参数
  if [ ${#space_params[@]} -ne 0 ]; then
    echo "以下输入参数包含空格："
    for param in "${space_params[@]}"; do
      echo "$param"
    done
  fi

  if [ ${#slash_params[@]} -ne 0 ]; then
    echo "以下输入参数包含斜杠："
    for param in "${slash_params[@]}"; do
      echo "$param"
    done
  fi

  if [ ${#colon_params[@]} -ne 0 ]; then
    echo "以下输入参数包含斜杠："
    for param in "${colon_params[@]}"; do
      printf "%s" "${param//://}"
        echo 
    done
  fi

  # 如果找到了任何一种无效的参数，则执行退出前删除操作
  if [ ${#space_params[@]} -ne 0 ] || [ ${#slash_params[@]} -ne 0 ] || [ ${#colon_params[@]} -ne 0 ]; then
    echo "所有输入参数都不能包含空格、斜杠或冒号。请检查后重新输入！"
    exit_delete_all
  else
    
    return
    # 脚本可以继续执行其他操作
    # ...
  fi
}

#返回值为0表示文件成功有效，为1表示文件失败
check_file() {
    local filename=$1
    local xmlname=""
    if [[ -z "$2" ]];then
    xmlname="${filename}"
    else
    xmlname="$2"
    fi

    # 检查文件是否存在
    if [ ! -f "$filename" ]; then
        #echo "${filename}文件不存在。"
        #printf "\033[31m${filename}文件不存在，注意检查\033[0m\n"
        printf "\033[31m${xmlname}中没有有效文件信息，注意检查\033[0m\n"
        return 1
    fi

    # 检查文件是否为空或只包含空白字符
    if [ -s "$filename" ] && [ -n "$(grep -E '\S' "$filename")" ]; then
        #echo "文件存在，不为空，且包含有效字符。"
        return 0
    else
        #echo "${filename}文件为空或没有有效字符。"
        printf "\033[31m${xmlname}中没有有效文件信息，注意检查\033[0m\n"
        return 1
    fi
}

ShowVolumesHuman(){
    #恢复单位初始设置为KB  
    Volume_Unit=KB
    #数值取整
    Volumes_In_Num=0
    #小数
    Volumes_In_Float="$1"

    if [ "$1" -ge 1024 ];then
        #return 1
        Volume_Unit=MB
        Volumes_In_Float=$(($1*1024/1048576))

        if [ "$Volumes_In_Float" -ge 1024 ];then
            Volumes_In_Float=$(echo "scale=2;$1*1024/1073741824"|bc)
            Volumes_In_Num=$(echo "$Volumes_In_Float"| awk '{print int($0)}')
            #return 2
            Volume_Unit=GB
            if [ "$Volumes_In_Num" -ge 1024 ];then
                Volumes_In_Float=$(echo "scale=2;$1*1024/1099511627776"|bc)
                Volumes_In_Num=$(echo "$Volumes_In_Float"| awk '{print int($0)}')
                #return 2
                Volume_Unit=TB
            fi
        fi
    fi
    echo "${Volumes_In_Float}${Volume_Unit}"
}

#定义文件名提取函数
#有两个输入参数第一个为xml文件名，第二个为需要输出合并的文件名
#函数功能为将xml文件的内容提取出来追加合并到第二个参数中的文件中去
FileNameExtract(){
    
    local InPutFileName="$1"
    local TempFileName="${RANDOM}_`date +%Y%m%d%H%M%S`"
    local OutputFileName="$2"
    #定义输入的xml文件类型旗标，
    #初始值为0代表文件为fcp7xml
    #1代表fcpxml
    #2代表fcpxmld文件
    IFFCPXxml_Flag=0
    #判断输入的文件类型
    if [[ "${InPutFileName##*.}" == fcpxml ]];then
      IFFCPXxml_Flag=1
    elif [[ "${InPutFileName##*.}" == fcpxmld ]];then
      IFFCPXxml_Flag=2
    else
      IFFCPXxml_Flag=0
      #确认是FCPX的xml文件，旗标变量赋值为1
    fi  
#判断文件类型采用不同的信息提取方法
    if [[ "$IFFCPXxml_Flag" == "0" ]];then
    	#如果旗标为0证明是FCP7xml文件,则使用FCP7的文件提取方法
        
        
    	cat "$InPutFileName" | grep "<pathurl>"|  sed -e '/<name>/d' | sed -e 's#^.*localhost##' |sed -e 's#</path.*$##g' > "${ChildrenDir}/${TempFileName}_UnDecoded_List"
    elif [[ "$IFFCPXxml_Flag" == "2" ]];then
    
    	cat "$InPutFileName/Info.fcpxml" | grep -E "src="  |  sed -e 's#^.*file://##' |sed -e s'#".*$##g' > "${ChildrenDir}/${TempFileName}_UnDecoded_List"
        
    else
    	#如果旗标为1证明是FCPXxml文件,则使用FCPX的文件提取方法
        #echo fcpis x
    	cat "$InPutFileName" | grep -E "src="  |  sed -e 's#^.*file://##' |sed -e s'#".*$##g' > "${ChildrenDir}/${TempFileName}_UnDecoded_List"
        
    fi



#    if [ "$Only_CopyAudioFiles_Flag" == "0" ];then
#    cat $InputFileName |  grep -E "<pathurl>file"  | sed -e 's#^.*localhost##' |sed -e 's#</path.*$##g' > "${TempFileName}_UnDecoded_List"
#        #cat $InputFileName | grep -E "src="  |  sed -e 's#^.*file://##' |sed -e s'#".*$##g'  > "${TempFileName}_UnDecoded_List"
#    else
#        #cat $InputFileName | grep -E "src="  |  sed -e 's#^.*file://##' |sed -e s'#".*$##g'  > "${TempFileName}_UnDecoded_List"
#        cat $InputFileName |  grep -E "<pathurl>file"  | grep -E ".AIF|.aif|.aiff|.AIFF|.WAV|.MP3|.wav|.mp3|.m4a|.M4A"| sed -e 's#^.*localhost##' |sed -e 's#</path.*$##g' > "${TempFileName}_UnDecoded_List"
#    fi
#如果文件不存在退出本次提取
    # 调用函数并传递文件路径作为参数
    if check_file "${ChildrenDir}/${TempFileName}_UnDecoded_List" ${InPutFileName}; then
        #echo "${InPutFileName}文件检查通过，可以继续执行后续操作。"
        :
    else
        #echo "文件检查失败，不执行后续操作。"
        #printf "\033[31m${InPutFileName}中没有有效文件信息，无任何文件拷贝，注意检查\033[0m\n"
        return
    fi

    while read filename;do
        printf $(printf "%s" "${filename}" | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g')"\n">>"${ChildrenDir}/${TempFileName}_Decoded_List"
    done < "${ChildrenDir}/${TempFileName}_UnDecoded_List"

#判断是否只提取音频
    if [[ "$Only_CopyAudioFiles_Flag" == "1" ]];then
    	#sed -i '/\.aif$\|\.AIF$\|\.aiff$\|\.AIFF$\|\.WAV$\|\.MP3$\|\.wav$\|\.mp3$\|\.m4a$/d' "$OutPutFileName-Decoded"
        grep -E '(\.aif|\.AIF|\.aiff|\.AIFF|\.WAV|\.MP3|\.wav|\.mp3|\.m4a)' "${ChildrenDir}/${TempFileName}_Decoded_List" > tmpfile
        #如果文件不存在退出本次提取
        if check_file tmpfile ${InPutFileName}; then
            #echo "文件检查通过，可以继续执行后续操作。"
            :
        else
            #echo "文件检查失败，不执行后续操作。"
            #printf "\033[31m${InPutFileName}中没有有效文件信息，无任何文件拷贝，注意检查\033[0m\n"
            return
        fi
        
        mv tmpfile "${ChildrenDir}/${TempFileName}_Decoded_List"
    else
    	true
    fi

    sed -i "" 's/amp;//g' "${ChildrenDir}/${TempFileName}_Decoded_List"
    grep -v '^\s*$' "${ChildrenDir}/${TempFileName}_Decoded_List" >> "${OutputFileName}"
    rm -rf "${ChildrenDir}/${TempFileName}_UnDecoded_List" "${ChildrenDir}/${TempFileName}_Decoded_List" 
}
#文件名提取函数定义完毕

#定义拷贝主函数
CopyFiles(){
    local FileList="$1"
    local index=1
    #xml名称
    local TheOtherDisk="$2"
    local Tips_Ing=正在拷贝
    local Tips_Skip=跳过拷贝
    local Tips_Force=强制拷贝
    
    local OffLineFileList=OffLineList_${RANDOM}.txt
    touch ${ChildrenDir}/${OffLineFileList}
    local TheNumOfOffLine=0
    Zongjindu=""
    ZongjinduNum=0
    TheWholeNumGuding=$allnum

    check_file "$FileList"  > /dev/null 2>&1
    local check_result=$?
    if [[ ${check_result} == 0 ]]; then
        #echo "文件检查通过，可以继续执行后续操作。"
        : 
    else
        #echo "文件检查失败，不执行后续操作。"
        #printf "\033[31m${InPutFileName}中没有有效文件信息，无任何文件拷贝，注意检查\033[0m\n"
        return
    fi


    local allnum=$(sed -n '$=' $FileList)
    while read filename;do
    #获取文件所在的硬盘的名称,如果不是以/Volumes开头则此变量为空，证明文件存在于Mac本机中
    #DiskNameInList=$(printf ${filename%/*} | sed -e "s#^.*/Volumes/##" |sed -e 's#/.*$##g')
        if [[ "${filename%/*}" == /Volumes/* ]]; then
            DiskNameInList=$(echo "$filename" | sed -e 's|^/Volumes/||' -e 's|/.*$||')
            #DiskNameInList=$(printf ${filename%/*} | sed -e "s#^.*/Volumes/##" |sed -e 's#/.*$##g')
            #echo "变量以/Volumes/开头，并且看起来像一个路径。"
        else
            #echo "变量不以/Volumes/开头，或者不是一个路径。"
            DiskNameInList=""
        fi        

        if [ "$Disk_To_Disk_Flag" == "1" ];then
        #如果这个变量为空，则说明源文件不在硬盘中
            if [[ -z "$DiskNameInList" ]];then
                Source_Path="$(printf "${filename%/*}")"
            else
                Source_Path="$(printf "${filename%/*}"|sed -e "s#^.*/Volumes/${DiskNameInList}##")"
            fi
        else
            Source_Path="$(printf "${filename%/*}" )"
        fi
        
    Dest_Path_Final="${Dest_Path}${Source_Path}"

        if [ "$Disk_To_Disk_Flag" == "1" ];then
            #加两个【是因为报错
            if [[ -z "$DiskNameInList" ]];then
                DestFileName="${Dest_Path}$(printf "${filename}")"
            else
                DestFileName="${Dest_Path}$(printf "${filename}"|sed -e "s#^.*/Volumes/${DiskNameInList}##")"
                true
            fi
        else
            DestFileName="${Dest_Path}$(printf "${filename}")"
            true
        fi
    SourceFileName="$(printf "$filename")"
    ShowName="$(printf "${DestFileName##*/}")"
    	if [[ -f ${SourceFileName} ]];then	
            if [ -d "$Dest_Path_Final"  ];then
    			  if [ ! -f "$DestFileName"  ];then
    			  	    printf "%10s      %-10s  %10s \n"  "${index}/${allnum} in ${TheOtherDisk}"   "$Tips_Ing" "${ShowName}" 
      		  	        cp -a "${SourceFileName}" "${Dest_Path_Final}"
                        if grep -qF -e "$DestFileName" "${ChildrenDir}/${CopyedList}"; then
                        :
                        else
                        SuccessCopyVolumes=$(($SuccessCopyVolumes + $(du -k "${SourceFileName}" | cut -f 1)))
                        echo "${DestFileName}" >> "${ChildrenDir}/${CopyedList}"
                        let SuccessCopyNum++
                        
                        fi
    			  	    let copy_num++
    			  	    let index++
    			  else 
                        if [[ ${Force_Copy_Flag} == 1 ]];then
                            #if [[ -f "${DestFileName}" ]];then

                            #fi
                            printf "%10s      %-10s  %10s \n"  "${index}/${allnum} in ${TheOtherDisk}"   "$Tips_Force" "${ShowName}" 
      		  	            cp -a "${SourceFileName}" "${Dest_Path_Final}"
                            if grep -qF -e "$DestFileName" "${ChildrenDir}/${CopyedList}"; then
                            # 如果 $DestFileName 存在于 ${CopyedList} 文件中，执行这里的代码
                                :
                            else
                                echo "${DestFileName}" >> "${ChildrenDir}/${CopyedList}"
                                SuccessCopyVolumes=$(($SuccessCopyVolumes + $(du -k "${SourceFileName}" | cut -f 1)))
                                let SuccessCopyNum++
                            fi

                        else
                            if grep -qF -e "$DestFileName" "${ChildrenDir}/${SkipedList}"; then
                            # 如果 $DestFileName 存在于 ${CopyedList} 文件中，执行这里的代码
                                :
                            else
                                echo "${DestFileName}" >> "${ChildrenDir}/${SkipedList}"
                                SkipVolumes=$(($SkipVolumes + $(du -k "${SourceFileName}" | cut -f 1)))
                                let SkipNum++
                            fi

                            printf "%10s     %-10s  %10s \n"  "${index}/${allnum} in ${TheOtherDisk}"  "$Tips_Skip" "${ShowName}"
                        fi 
    			  	    let exist_num++
    			  	    let index++
    			  fi
    		else
      			  mkdir -p "$Dest_Path_Final"
    			  printf "%10s      %-10s  %10s \n"  "${index}/${allnum} in ${TheOtherDisk}" "$Tips_Ing" "${ShowName}" 

    			  cp -a "${SourceFileName}" "${Dest_Path_Final}"
                  if grep -qF -e "$DestFileName" "${ChildrenDir}/${SkipedList}"; then
                  :
                  else
                  SuccessCopyVolumes=$(($SuccessCopyVolumes + $(du -k "${SourceFileName}" | cut -f 1)))
                  let SuccessCopyNum++
                  echo "${DestFileName}" >> "${ChildrenDir}/${CopyedList}"
                  fi
    			  let copy_num++
    			  let index++
    		fi
        else
            echo ${SourceFileName} >> "${ChildrenDir}/${OffLineFileList}"
            let TheNumOfOffLine++
        fi    
    let TheWholeIndex++
    #ZongjinduNum=$(printf "%d%%" $(($TheWholeIndex*100/$TheWholeNumGuding)))
    done < "${FileList}"

    if [[ $TheNumOfOffLine -gt 0 ]];then
    echo "以下文件离线："
    cat "${ChildrenDir}/${OffLineFileList}"
    fi
    rm -rf "${ChildrenDir}/${OffLineFileList}"
}


#将输入的文件列表分为离线，在线，存在目标盘，不存在目标盘输出四个文件,如果只计算大小则不去辨别是否存在目标位置
SeparateFiles(){
    #输入文件为XML文件 和输出文件
    local SFInputFileName="$1"
    local Not_Exist_Num=0
    local Exist_Num=0
    local Num_In_Mac=0
    local NumOfOffLine=0
    local NumOfOnLine=0
    local File_Volumes_Existed=0
    local File_Volumes_NotExisted=0
    local File_Volumes_Online=0
    local File_Volumes_Offline=0
    local File_Volumes_InMac=0
    local File_Separated="`date +%Y%m%d%H%M%S`_${RANDOM}_Separated"
    local this_xmlfile=""
    touch "${ChildrenDir}/${File_Separated}_not_exist_at_dest.txt"
    touch "${ChildrenDir}/${File_Separated}_exist.txt"
    touch "${ChildrenDir}/${File_Separated}_offline.txt"
    touch "${ChildrenDir}/${File_Separated}_online.txt"
    touch "${ChildrenDir}/${File_Separated}_inMac.txt"
    
    #判断第一个输入的文件类型
    InputFileType=${SFInputFileName##*[.]}
    if [[ "$InputFileType" == "xml" ]] || [[ "$InputFileType" == "fcpxmld" ]] || [[ "$InputFileType" == "fcpxml" ]];then
        this_xmlfile="$1"
    #如果输入的是xml文件则转化为txt的文件列表
        FileNameExtract "$1" "${ChildrenDir}/${File_Separated}.txt"
        if [ ! -f "${ChildrenDir}/${File_Separated}.txt" ]; then
            #echo "${filename}文件不存在。"
            #printf "\033[31m${filename}文件不存在，注意检查\033[0m\n"
            #printf "\033[31m${xmlname}中没有有效文件信息，注意检查\033[0m\n"
            return 1
        fi

        # 检查文件是否为空或只包含空白字符
        if [ -s "${ChildrenDir}/${File_Separated}.txt" ] && [ -n "$(grep -E '\S' "${ChildrenDir}/${File_Separated}.txt")" ];then
            #echo "文件存在，不为空，且包含有效字符。"
            #return 0
            :
        else
            #echo "${filename}文件为空或没有有效字符。"
            #printf "\033[31m${xmlname}中没有有效文件信息，注意检查\033[0m\n"
            return 1
        fi        
        
    else
    #如果是txt文件则赋值给内部可用的文档
        #检查文件有效性
        if check_file "${SFInputFileName}"; then
           #echo "文件检查通过，可以继续执行后续操作。"
           :
        else
           #echo "文件检查失败，不执行后续操作。"
           #printf "\033[31m${SFInputFileName}中没有有效文件信息，无任何文件拷贝，注意检查\033[0m\n"
           return
        fi
        cat "${SFInputFileName}" > "${ChildrenDir}/${File_Separated}.txt"
    fi
    #提取输入的xml的文件名
    #local TheOtherDisk="${SFInputFileName%%.*}"
    
    #检查文件有效性
    if check_file "${ChildrenDir}/${File_Separated}.txt"; then
       #echo "文件检查通过，可以继续执行后续操作。"
       :
    else
       #echo "文件检查失败，不执行后续操作。"
       #printf "\033[31m${ChildrenDir}/${File_Separated}.txt中没有有效文件信息，无任何文件拷贝，注意检查\033[0m\n"
       return
    fi
    #查看文档的行数
    local NumOfAllList=$(sed -n '$=' "${ChildrenDir}/${File_Separated}.txt")
    while read filename;do
        #获取列表中文件所在的硬盘的名称
        if [[ "${filename%/*}" == /Volumes/* ]]; then
            DiskNameInList=$(echo "$filename" | sed -e 's|^/Volumes/||' -e 's|/.*$||')
            #DiskNameInList=$(printf ${filename%/*} | sed -e "s#^.*/Volumes/##" |sed -e 's#/.*$##g')
            #echo "变量以/Volumes/开头，并且看起来像一个路径。"
        else
            #echo "变量不以/Volumes/开头，或者不是一个路径。"
            DiskNameInList=""
        fi        

        
        if [ "$Disk_To_Disk_Flag" == "1" ];then
            if [[ -z "$DiskNameInList" ]];then
            #如果变量为空证明该行文件不存在任何外挂硬盘中，在Mac本机位置，所以加上xml文件名的前缀，以确认是否在目的位置存在相同文件
                #Source_Path="/${TheOtherDisk}$(printf "${filename%/*}")"
                Source_Path="$(printf "${filename%/*}")"
            else
            #变量不为空证明该文件存在于某块硬盘内，那么可以将前边硬盘名称前缀去掉用于后边的比对
                Source_Path=$(printf "${filename%/*}"|sed -e "s#^.*/Volumes/${DiskNameInList}##")
            fi
        else
        #如果不是硬盘对硬盘的拷贝那么目的地址是没有任何文件的，所以不需要进行比对
            Source_Path=$(printf "${filename%/*}" )
        fi
        #注意如果是硬盘对硬盘的拷贝模式，这里的Source_path是去掉了前缀的，所以下边在其那边加上Dest_Path就是目标地址
        Dest_Path_Final="${Dest_Path}${Source_Path}"

        if [ "$Disk_To_Disk_Flag" == "1" ];then
            #加两个【是因为报错
            if [[ -z "$DiskNameInList" ]];then
                DestFileName="${Dest_Path}$(printf "${filename}")"
            else
                DestFileName="${Dest_Path}$(printf "${filename}"|sed -e "s#^.*/Volumes/${DiskNameInList}##")"
                true
            fi
        else
            DestFileName="${Dest_Path}$(printf "${filename}")"
            true
        fi

        if [[ "$Only_Volume_Calculate_Flag" == "1" ]];then
            if [[ -f "${filename}" ]];then
                echo "${filename}" >> "${ChildrenDir}/${File_Separated}_online.txt"
                File_Volumes_Online=$(($File_Volumes_Online + $(du -k "${filename}" | cut -f 1)))
                let NumOfOnLine++
                if [[ -z "$DiskNameInList" ]];then
                    echo "${filename}" >> "${ChildrenDir}/${File_Separated}_inMac.txt"
                    File_Volumes_InMac=$(($File_Volumes_InMac + $(du -k "${filename}" | cut -f 1)))
                    let Num_In_Mac++
                fi
                
            else
                echo "${filename}" >> "${ChildrenDir}/${File_Separated}_offline.txt"
                let NumOfOffLine++
            fi

        else
            if [[ -f "${filename}" ]];then
                File_Volumes_Online=$(($File_Volumes_Online + $(du -k "${filename}" | cut -f 1)))
                let NumOfOnLine++
                if [ ! -f "$DestFileName"  ];then
                    echo "${filename}" >> "${ChildrenDir}/${File_Separated}_not_exist_at_dest.txt"
                    File_Volumes_NotExisted=$(($File_Volumes_NotExisted + $(du -k "${filename}" | cut -f 1)))
                    let Not_Exist_Num++
                else
                	echo "${filename}" >> "${ChildrenDir}/${File_Separated}_exist.txt"
                    File_Volumes_Existed=$(($File_Volumes_Existed + $(du -k "${filename}" | cut -f 1)))
                    let Exist_Num++
                fi
            
                if [[ -z "$DiskNameInList" ]];then
                    echo "${filename}" >> "${ChildrenDir}/${File_Separated}_inMac.txt"
                    File_Volumes_InMac=$(($File_Volumes_InMac + $(du -k "${filename}" | cut -f 1)))
                    let Num_In_Mac++
                fi
            else
                echo "${filename}" >> "${ChildrenDir}/${File_Separated}_offline.txt"
                let NumOfOffLine++
            fi
        fi     
    done < "${ChildrenDir}/${File_Separated}.txt"

    #如果存在第二个参数把待拷贝的文件写入列表里
    if [ ! -z $2 ];then
        cat "${ChildrenDir}/${File_Separated}_not_exist_at_dest.txt" > $2
    else
        true
    fi 
    #如果存在第三个参数把已经存在的文件写入列表里
    if [ ! -z $3 ];then
        cat "${ChildrenDir}/${File_Separated}_exist.txt" > $3
    else
        true
    fi

    if [[ "$Only_Volume_Calculate_Flag" == "1" ]];then
       
        
        #echo "源文件存在Mac中的文件个数为${Num_In_Mac}个,共计$(ShowVolumesHuman $File_Volumes_InMac)" 
        
        
        if [[ ${NumOfOffLine} == 0 ]];then    
            :
        else
            echo "离线文件列表："
            cat "${ChildrenDir}/${File_Separated}_offline.txt"
            #echo "XML中有${NumOfAllList}个文件，其中成功链接的在线文件${NumOfOnLine}个$(ShowVolumesHuman $File_Volumes_Online)，离线文件${NumOfOffLine}个"
            #printf "XML中有%s个文件，其中成功链接的在线文件%s个%s，离线文件%s个" "${NumOfAllList}" "${NumOfOnLine}" "$(ShowVolumesHuman $File_Volumes_Online)" "${NumOfOffLine}"    
        fi  
        printf "XML中有%s个文件，其中成功链接的在线文件%s个%s" "${NumOfAllList}" "${NumOfOnLine}" "$(ShowVolumesHuman $File_Volumes_Online)"
        if [[ ${NumOfOffLine} == 0 ]];then    
            :
        else    
        printf "，离线文件%s个\n" "${NumOfOffLine}"    
        fi  
        echo 
    else       
        
        #echo "源文件存在Mac中的文件个数为${Num_In_Mac}个,共计$(ShowVolumesHuman $File_Volumes_InMac)" 
        if [[ ${NumOfOffLine} == 0 ]];then
            echo "XML中有${NumOfAllList}个文件，其中在线文件${NumOfOnLine}个共计$(ShowVolumesHuman $File_Volumes_Online)，目标位置已经存在${Exist_Num}个文件$(ShowVolumesHuman $File_Volumes_Existed)"
        else
            echo "离线文件列表："
            cat "${ChildrenDir}/${File_Separated}_offline.txt"
            echo "XML中有${NumOfAllList}个文件，其中在线文件${NumOfOnLine}个共计$(ShowVolumesHuman $File_Volumes_Online)，离线文件${NumOfOffLine}个，目标位置已经存在${Exist_Num}个文件$(ShowVolumesHuman $File_Volumes_Existed)"
            
        fi        
        
        #TheWholeNum=$((${Not_Exist_Num}+${Num_In_Mac}))
    
    fi
    #echo 开始拷贝
    rm -rf ${ChildrenDir}/${File_Separated}_not_exist_at_dest.txt ${ChildrenDir}/${File_Separated}_exist.txt ${ChildrenDir}/"${File_Separated}.txt" ${ChildrenDir}/"${File_Separated}_offline.txt"  ${ChildrenDir}/"${File_Separated}_online.txt" ${ChildrenDir}/"${File_Separated}_inMac.txt"
}


#主程序开始


#判断是删除还是拷贝功能
Delete_Temp_Files="Temp_${RANDOM}__`date +%Y%m%d%H%M%S`"
# 定义分隔符
separator="except"
All_To_Delete=filenamelist_to_delete_${RANDOM}.txt
Not_To_Delete=filenamelist_not_delete_${RANDOM}.txt
# 判断删除函数参数是否正确，并将输入xml文件分类整理的删除函数
prepare_delete_files_list() {
    # 第一个参数
    del_param=$1
    local exit_code=0  # 用于记录是否找到包含空格的参数
    # 待删除文件列表和不删除文件列表
    files_to_delete=()
    files_to_keep=()
    
    # 检查是否输入了删除参数
    if [ "$del_param" == "del" ]; then
        # 移除第一个参数，剩下的参数重新作为$@
        shift
        
        # 初始化变量以检查是否有合规的文件名
        has_valid_file_before=false
        has_valid_file_after=false
        separator_found=false
        
        # 初始化一个空的数组来存储所有文件名
        all_files=()
        # 使用 "$@" 来遍历所有参数检查是否有空格输入
        check_input_params "$@"
        for arg in "$@"; do
          if [[ "$arg" == *" "* ]]; then
            echo "参数 '$arg' 包含空格。"
            exit_code=1  # 设置退出代码为1，表示找到包含空格的参数
          fi
        done

        # 如果找到包含空格的参数，则退出函数
        if [ "$exit_code" -ne 0 ]; then
          
          echo "输入的文件名包含空格，请检查后重新输入"
          exit_delete_all
        else
          #echo "所有参数都不包含空格，继续执行函数。"
          # 这里可以放置函数的其余部分
        :
        fi

        # 检查每个参数是否符合文件类型要求
        for arg in "$@"; do
        
            if [[ "$arg" == "$separator" ]]; then
                if [[ $separator_found == "true" ]];then
                    echo 参数输入中不能出现多个except
                    exit_delete_all
                fi
                separator_found=true
            elif [[ "$arg" == *.xml ]] || [[ "$arg" == *.fcpxml ]] || [[ "$arg" == *.fcpxmld ]]; then
                # 检查文件名是否唯一
                
                if [[ " ${all_files[*]} " == *" $arg "* ]]; then
                    echo "输入错误：文件 '$arg' 重复。"
                    exit_delete_all
                else
                    all_files+=("$arg")
                    if [ "$separator_found" = true ]; then
                        has_valid_file_after=true
                        files_to_keep+=("$arg")
                    else
                        has_valid_file_before=true
                        files_to_delete+=("$arg")
                    fi
                fi
            else
                echo "输入错误：文件 '$arg' 的类型不符合要求，必须是 .xml, .fcpxml, 或 .fcpxmld。"
                exit_delete_all
            fi
        done
        
        # 根据分隔符和文件类型存在性检查参数数量
        if ! $separator_found; then
            if [ $# -eq 0 ] || ! $has_valid_file_before; then
                echo "输入参数不合法：至少需要一个合规的文件名。"
                exit_delete_all
            fi
        else
            if ! $has_valid_file_before || ! $has_valid_file_after; then
                echo "输入参数不合法：分隔符 '$separator' 两侧都需要至少一个合规的文件名。"
                exit_delete_all
            fi
        fi
        # 输出待删除的文件列表
        echo "待删除的文件列表: ${files_to_delete[*]}"
        for file in "${files_to_delete[@]}"; do
            #echo "$file"
            FileNameExtract "$file" "${ChildrenDir}/${All_To_Delete}"
        done    
        #cat    "${ChildrenDir}/${All_To_Delete}"
        # 如果不删除列表不为空，则输出该列表
        if [ "${#files_to_keep[@]}" -ne 0 ]; then
            echo "不删除的文件列表: ${files_to_keep[*]}"
            for file in "${files_to_keep[@]}"; do
                #echo "$file"
                FileNameExtract "$file" "${ChildrenDir}/${Not_To_Delete}"
            done
        fi

        check_file "${ChildrenDir}/${All_To_Delete}" > /dev/null 2>&1
        local check_result=$?
        if [[ ${check_result} == 0 ]]; then
            :
             
        else
            #echo "文件检查失败，不执行后续操作。"
            #printf "\033[31m${InPutFileName}中没有有效文件信息，无任何文件拷贝，注意检查\033[0m\n"
            echo "待删除xml文件中没有有效信息，请检查后重新输入"
            return
            
        fi

        check_file "${ChildrenDir}/${Not_To_Delete}" > /dev/null 2>&1
        local to_keep_check_result=$?
        if [[ $separator_found == "true" ]];then

            if [[ ${to_keep_check_result} == 0 ]]; then
                :

            else
                #echo "文件检查失败，不执行后续操作。"
                #echo $separator_found
                #printf "\033[31m${InPutFileName}中没有有效文件信息，无任何文件拷贝，注意检查\033[0m\n"
                echo "需要保留的xml文件中没有有效信息，请注意检查后重新输入"
                return 

            fi
        else
        :
        fi

        # 如果不需要删除的文件存在，进行排序和比较
        if [ -n "${ChildrenDir}/${Not_To_Delete}" ] && [[ -f "${ChildrenDir}/${Not_To_Delete}" ]]; then
            # 对两个文件进行排序
            sort -u ${ChildrenDir}/"${All_To_Delete}" -o ${ChildrenDir}/"${All_To_Delete}"
            sort -u ${ChildrenDir}/"${Not_To_Delete}" -o ${ChildrenDir}/"${Not_To_Delete}"
            #echo 执行了

            # 使用comm命令比较两个文件，仅保留第一个文件中独有的行
            comm -23 ${ChildrenDir}/"${All_To_Delete}" ${ChildrenDir}/"${Not_To_Delete}" > ${ChildrenDir}/"${All_To_Delete}.tmp" && mv ${ChildrenDir}/"${All_To_Delete}.tmp" ${ChildrenDir}/"${All_To_Delete}"

            if [ $? -eq 0 ]; then
                #echo "文件 '${All_To_Delete}' 已更新，删除了所有在 '${Not_To_Delete}' 中出现的行。"
                :
            else
                echo "在处理合成文件时发生错误。"
                exit_delete_all
            fi
            #查看最后的文件是否为空
            check_file ${All_To_Delete}  > /dev/null 2>&1
            local check_result=$?
            if [[ ${check_result} == 0 ]]; then
                :

            else
                #echo "文件检查失败，不执行后续操作。"
                #printf "\033[31m${InPutFileName}中没有有效文件信息，无任何文件拷贝，注意检查\033[0m\n"
                echo "计算后xml文件中都没有待删除的文件有效信息，请检查后重新输入"
                return
            fi
            
        else
            
                    # 检查是否提供了文件列表
            if [ ! -f "${ChildrenDir}/${All_To_Delete}" ]; then
                echo "所有xml文件中没有有效信息，请检查后重新输入。没有任何文件被删除"
                exit_delete_all
            else
            # 如果只提供了一个文件，可以在这里添加其他逻辑（如果需要）
            sort -u "${ChildrenDir}/${All_To_Delete}" -o "${ChildrenDir}/${All_To_Delete}"

            fi
            
        fi

        #cat "${ChildrenDir}/${All_To_Delete}"
        mkdir -p "$Delete_Temp_Files"
        # 遍历文件列表中的每个文件，并将它们复制到 Delete_Temp_Files 目录
        while IFS= read -r file_to_process; do
            # 检查文件是否存在
            if [ -f "$file_to_process" ]; then
                # 复制文件到 Delete_Temp_Files 目录，保留原目录结构
                # 使用 dirname 和 basename 获取文件的目录和名称
                #echo "$file_to_process"
                local dir=$(dirname "$file_to_process")
                #echo  $dir
                local filename=$(basename "$file_to_process")
                #echo $filename
                # 创建相应的子目录，如果有必要的话
                mkdir -p "$Delete_Temp_Files/$dir"
                # 执行复制操作
                cp "$file_to_process" "$Delete_Temp_Files/$dir/$filename"
                #osascript -e "tell application \"Finder\" to move POSIX file \"$file_to_process\" to trash"
                #mv "$file_to_process"  ~/.Trash/
                echo "移动 '$file_to_process' 到 '$Delete_Temp_Files/$dir/$filename'"
                #echo "移动 '$file_to_process' 到 回收站"
            else
                echo "警告：文件 '$file_to_process' 不存在，跳过。"
            fi
        done < "${ChildrenDir}/${All_To_Delete}"

        #echo "所有列出的文件已被移动到 '$Delete_Temp_Files' 目录中。"
        echo "所有列出的文件已被移动到${Delete_Temp_Files}中，请确认后手动删除"

        # 检查 "All_To_Delete" 文件是否存在，如果存在则删除
        if [ -f "${ChildrenDir}/$All_To_Delete" ]; then
            rm -rf "${ChildrenDir}/$All_To_Delete"
            #echo "已删除文件: $All_To_Delete"
        fi
        # 检查 "Not_To_Delete" 文件是否存在，如果存在则删除
        if [ -f "${ChildrenDir}/$Not_To_Delete" ]; then
            rm -rf "${ChildrenDir}/$Not_To_Delete"
            #echo "已删除文件: $Not_To_Delete"
        fi
        exit_delete_all        
    else
        echo "进入文件整理模式"
        return 1
    fi
}


#只删除模式
only_calcu_volume() {
    # 检查第一个参数是否为 'c'
    if [ "$1" == "c" ]; then
        # 移除第一个参数，剩下的参数重新作为 "$@"
        shift
        local exit_code=0  # 用于记录是否找到包含空格的参数

        #检查输入参数
        check_input_params "$@"

        # 使用 "$@" 来遍历所有参数检查是否有空格输入
        for arg in "$@"; do
          if [[ "$arg" == *" "* ]]; then
            echo "参数 '$arg' 包含空格。"
            exit_code=1  # 设置退出代码为1，表示找到包含空格的参数
          fi
        done

        # 如果找到包含空格的参数，则退出函数
        if [ "$exit_code" -ne 0 ]; then
         
          echo "输入的文件名包含空格，请检查后重新输入"
           exit_delete_all
        else
          #echo "所有参数都不包含空格，继续执行函数。"
          # 这里可以放置函数的其余部分
        :
        fi

        # 初始化一个空的数组来存储已经检查过的文件名
        declared_files=()

        # 循环遍历所有参数
        for file in "$@"; do
            # 检查文件扩展名是否合法
            if [[ ! "$file" =~ \.(xml|fcpxml|fcpxmld)$ ]]; then
                echo "错误：文件 '$file' 的扩展名不是 .xml, .fcpxml 或 .fcpxmld"
                return 1 # 返回错误代码
            fi

            # 检查文件是否存在
            if [ ! -e "$file" ]; then
                echo "错误：文件 '$file' 不存在。"
                return 1 # 返回错误代码
            fi

            # 检查文件名是否重复
            if [[ " ${declared_files[*]} " == *" $file "* ]]; then
                echo "错误：文件 '$file' 重复。"
                return 1 # 返回错误代码
            else
                # 如果没有重复，将文件名添加到数组中
                declared_files+=("$file")
            fi
        done

        local All_clac_list=All_${RANDOM}_Calc.txt
        touch "${ChildrenDir}/${All_clac_list}"

        # 如果所有检查都通过，则处理文件
        for file in "${declared_files[@]}"; do
            # 调用另一个函数处理每个文件
            FileNameExtract "$file" "${ChildrenDir}/${All_clac_list}"
            #process_file "$file"
        done
        #检查文件是否有效
        check_file "${ChildrenDir}/${All_clac_list}"  > /dev/null 2>&1
        local check_result=$?
        if [[ ${check_result} == 0 ]]; then
            :
             
        else
            #echo "文件检查失败，不执行后续操作。"
            #printf "\033[31m${InPutFileName}中没有有效文件信息，无任何文件拷贝，注意检查\033[0m\n"
            echo "所有xml文件中都没有有效信息，请检查后重新输入"
            return
            
        fi
        
        sort -u "${ChildrenDir}/${All_clac_list}" -o "${ChildrenDir}/${All_clac_list}"
    
        SeparateFiles "${ChildrenDir}/${All_clac_list}"
        
        rm -rf "${ChildrenDir}/${All_clac_list}"
    else
        # 如果第一个参数不是 'c'，则不执行任何操作
        return 0
    fi
}


# 检查第一个参数
case "$1" in
    帮助)
        # 输出帮助信息并退出
        echo "本文档，可轻松通过xml文档将主盘的素材分集拷贝到另外同名的盘中，要求xml文档必须能够连接源盘中的文件"
        echo "需要传递7个参数"
        echo "第一个参数 f or n  f表示强制覆盖已经存在的文件 n 表示跳过已经存在的文件"
        echo "第二个参数 yes or no yes表示需要暂停确认列表中的文件，no表示相反的意思"
        echo "第三个参数 uc or c 是否仅仅计算大小，c表示仅仅计算文件大小，uc表示不仅仅计算大小"
        echo "第四个参数 是否仅拷贝音频 audio all"
        echo "第五个参数 是否硬盘对硬盘拷贝"
        echo "第六个参数 为目标硬盘名称"
        echo "第七个参数为需要拷贝的文件的fcp7的Xml文件"
        echo "FileManage n|f no|yes uc|c all|audio dd|ndd \"JZDSBC\"  test.xml"
        echo "如果第一个参数是 del 则进入删除模式，删除模式的分割符是 except"
        echo "如果没有 except 的话，会整合所有的 xml 文件将其对应的内容删除"
        echo "如果有 except 的话会只删除except 前边的 xml 中对应的文件"
        echo "FileManage del *.xml *.xml except x.xml x.xml"
        exit_delete_all
        ;;
    del)
        prepare_delete_files_list "$@"
        exit_delete_all
        exit 0
        ;; 
    c)
        Only_Volume_Calculate_Flag=1
        only_calcu_volume "$@"
        exit_delete_all
        exit 0
        ;;
    *)
        # 如果第一个参数不是 /?，则执行后续代码
        ;;
esac

# 调用函数，传递所有命令行参数给prepare_delete_files_list函数

#判断参数是否输入正确
if [ -z "$7" ];then 
    echo "未输入足够参数"
    exit 1
fi 
#是否需要强制覆盖
fugai=$1
if [ "$1" == "f" ];then
Force_Copy_Flag=1
    echo "文件将强制覆盖"
elif [ "$1" == "n" ];then
Force_Copy_Flag=0
    echo "会跳过已经存在的文件"
else
    echo 第一个参数输入错误请重新输入
    exit 8	
fi
#是否需要等待确认
confirm=$2
if [ "$2" == "yes" ];then
    echo "拷贝需确认"
elif [ "$2" == "no" ];then
    echo "拷贝无需确认"
else
    echo 第二个参数输入错误请重新输入
    exit 8	
fi
#第三个参数是否只计算文件大小
Only_Volume_Calculate_Flag=0
if [ "$3" == "c" ];then
    echo "只计算待拷贝文件大小"
    Only_Volume_Calculate_Flag=1
elif [ "$3" == "uc" ];then
    echo "计算待拷贝文件大小且拷贝文件"
    Only_Volume_Calculate_Flag=0
else
    echo 第三个参数输入错误请重新输入
    exit 8	
fi
#第四个参数是否只拷贝音频文件
Only_CopyAudioFiles_Flag=0
if [ "$4" == "audio" ];then
    echo "只拷贝音频文件"
    Only_CopyAudioFiles_Flag=1
elif [ "$4" == "all" ];then
    echo "拷贝所有文件"
    Only_CopyAudioFiles_Flag=0
else
    echo 第四个参数输入错误请重新输入
    exit 8	
fi
#是否硬盘对硬盘直接拷贝
Disk_To_Disk_Flag=0
if [ "$5" == "dd" ];then
    echo "硬盘对硬盘"
    Disk_To_Disk_Flag=1
    #提取目标硬盘名称，第五个参数目标地址
elif [ "$5" == "ndd" ];then
    echo "硬盘对路径"
    Disk_To_Disk_Flag=0
else
    echo 第五个参数输入错误请重新输入
    exit 8	
fi
#拷贝的目标路径
if [ ! -z "$6" ];then 
    Dest_Path_Input="$6"
else
    echo "未输入目标路径"
    exit 1
fi 
#判断目标盘是否存在
if [ "$Disk_To_Disk_Flag" == "1" ];then
    # "硬盘对硬盘"
    #提取目标硬盘名称，第五个参数目标地址
    Dest_Disk_Path="$(echo "${Dest_Path_Input}" | sed "s#^/Volumes/##")"
    Dest_Disk_Name="${Dest_Disk_Path%%[/]*}"
    Dest_Path="/Volumes/${Dest_Disk_Name}"
    if [ -d "$Dest_Path"  ];then
        echo "目标硬盘:$Dest_Disk_Name 已经存在，可以拷贝"
    else
        echo "目标硬盘:$Dest_Disk_Name 不存在，请重新输入"
    	  exit 8
    fi
else
    Dest_Path="$Dest_Path_Input"
fi

#参数循环，跳过前两个参数 从第七个开始 计算拷贝的文件
Canshu_Num=$#
Canshu_Index=1
All_Files=AllFilesList_${RANDOM}
TheWholeNum=0
TheWholeIndex=0


# 将所有命令行参数作为数组处理
allargs=("$@")

# 从第六个参数开始（索引为5，因为数组索引从0开始）获取所有参数
# 使用数组切片传递给 check_input_params 函数
check_input_params "${allargs[@]:6}"

Include_Space=0
# 使用 "$@" 来遍历所有参数检查是否有空格输入
for arg in "$@"; do
  if [[ "$arg" == *" "* ]]; then
    echo "参数 '$arg' 包含空格。"
    Include_Space=1  # 设置退出代码为1，表示找到包含空格的参数
  fi
done
# 如果找到包含空格的参数，则退出函数
if [ "$Include_Space" -ne 0 ]; then
  echo "输入的文件名包含空格，请检查后重新输入"
  exit_delete_all
  
else
  #echo "所有参数都不包含空格，继续执行函数。"
  # 这里可以放置函数的其余部分
:
fi

for arg in "$@"
do
    if [ "$Canshu_Index" -le 6 ];then
        let Canshu_Index+=1
        
        true
    else
        #提取文件名存储在All_Files.txt里
        #echo "操作${arg}"
        
        FileNameExtract $arg ${ChildrenDir}/${All_Files}.txt
        
        let Canshu_Index+=1
    fi
done
#文件排序去重

check_file ${ChildrenDir}/${All_Files}.txt > /dev/null 2>&1
All_xml_check_result=$?
if [[ ${All_xml_check_result} == 0 ]]; then
    :
     
else
    #echo "文件检查失败，不执行后续操作。"
    #printf "\033[31m${InPutFileName}中没有有效文件信息，无任何文件拷贝，注意检查\033[0m\n"
    echo "所有xml文件中都没有有效信息，请检查后重新输入"
    exit_delete_all
    
fi

sort -u ${ChildrenDir}/${All_Files}.txt > ${ChildrenDir}/${All_Files}_UniqueList.txt
#echo 结束
#cat  ${ChildrenDir}/${All_Files}_UniqueList.txt
SeparateFiles "${ChildrenDir}/${All_Files}_UniqueList.txt" | tee  ${ChildrenDir}/${All_Files}_temp.txt
#TheWholeNumGuding="$TheWholeNum"
rm -rf "${ChildrenDir}/${All_Files}.txt" "${ChildrenDir}/${All_Files}_UniqueList.txt"

#如果只计算大小的话，到此结束退出程序
if [ "$Only_Volume_Calculate_Flag" == "1" ];then
    exit_delete_all
else
    true
fi
clear
echo "文件信息整理完毕开始正式拷贝"
#正式开始拷贝
touch ${ChildrenDir}/${SkipedList}
touch ${ChildrenDir}/${CopyedList}
Canshu_Index=1 
for arg in "$@"
do
    if [ "$Canshu_Index" -le 6 ];then
        let Canshu_Index+=1
        true
    else
        printf "%s : \n" $arg
        #把已经存在的文件拆分出来
        SeparateFiles $arg ${ChildrenDir}/${arg%%.*}_no_existed ${ChildrenDir}/${arg%%.*}_existed
        #echo "${arg}开始拷贝"
        
        if [[ -f ${ChildrenDir}/${arg%%.*}_no_existed ]];then
        CopyFiles ${ChildrenDir}/${arg%%.*}_no_existed ${arg%%.*}
        else
        :
        fi

        if [[ -f ${ChildrenDir}/${arg%%.*}_existed ]];then
        CopyFiles ${ChildrenDir}/${arg%%.*}_existed ${arg%%.*}
        else
        :
        fi
        
        if [[ ! -f ${ChildrenDir}/${arg%%.*}_existed ]] && [[ -f ${ChildrenDir}/${arg%%.*}_existed ]];then
        
        printf "\033[31m${arg}中没有有效文件信息，注意检查\033[0m\n"
        fi

        echo "${arg}拷贝结束"
        echo
        rm -rf ${ChildrenDir}/${arg%%.*}_existed ${ChildrenDir}/${arg%%.*}_no_existed
        let Canshu_Index+=1
    fi
done

cat ${ChildrenDir}/${All_Files}_temp.txt
#SeparateFiles "${All_Files}_UniqueList.txt"
#TheWholeNumGuding="$TheWholeNum"
rm -rf ${ChildrenDir}/${All_Files}_temp.txt

# 检查文件是否存在
if [[ -f "${ChildrenDir}/${SkipedList}" ]]; then
    # 文件存在，执行删除操作
    rm -rf "${ChildrenDir}/${SkipedList}"
fi

if [[ -f "${ChildrenDir}/${CopyedList}" ]]; then
    # 文件存在，执行删除操作
    rm -rf "${ChildrenDir}/${CopyedList}"
fi
#，跳过${SkipNum}个文件$(ShowVolumesHuman $SkipVolumes)
echo "成功拷贝${SuccessCopyNum}个文件$(ShowVolumesHuman $SuccessCopyVolumes)"
exit_delete_all
EOF
chmod +x ~/${CoreFileProcess}

select_external_disks() {
    # 初始化卷计数器
    local volume_count=0

    local VOLUME_NAME
    local user_path

    # 遍历/Volumes目录下的每个条目
    for volume in /Volumes/*; do
        if [ -d "$volume" ]; then
            volumes[$volume_count]=$(basename "$volume") # 存储卷的名称
            ((volume_count++))
        fi
    done

    # 如果没有找到卷，则输出提示信息并退出函数
    if [ $volume_count -eq 0 ]; then
        echo "未检测到挂载的卷。"
        return 0
    fi

    # 列出卷供用户选择，包括输入自定义路径的选项
# 函数开始部分保持不变...

# 列出卷供用户选择，包括输入自定义路径的选项
echo "以下是检测到的挂载卷，请选择一个进行拷贝："
for (( i=0; i<volume_count; i++ )); do
    echo "$((i+1))) ${volumes[i]}"
done
echo "$((volume_count + 1))）输入自定义路径 "

# 读取用户选择的卷编号
read -p "请输入卷编号 (1-$((volume_count + 1))) : " choice

# 检查用户输入是否有效
if [[ $choice =~ ^[0-9]+$ ]]; then
    if (( choice > 0 && choice <= volume_count )); then
        # 根据用户选择设置卷的变量
        VOLUME_NAME=${volumes[$((choice - 1))]}
        echo "您选择的卷是: $VOLUME_NAME"
        Dest_Path_Input="/Volumes/$VOLUME_NAME"
    elif (( choice == volume_count + 1 )); then
        # 用户选择了输入自定义路径
        read -p "请输入自定义路径: " user_path
        if [ -d "$user_path" ]; then
            Dest_Path_Input="$user_path"
            FatherDisk_To_Disk_Flag=0 # 用户选择了自定义路径，设置标记为0
        else
            echo "输入的路径不存在。"
            return 1 # 返回错误状态码
        fi
    else
        echo "无效的输入，操作取消。"
        return 1 # 返回错误状态码
    fi
else
    echo "无效的输入，请输入一个数字。"
    return 1 # 返回错误状态码
fi

# 函数其余部分保持不变...

    # 调用operate_on_disk函数进行操作
    # operate_on_disk "$Dest_Path_Input"
}
FatherAudioOrAll=all
# 调用函数
only_calc_wait(){
        echo -e "请输入一个数字\033[32m（1-2）\033[0m选择相应选项，\033[32m默认选项为2\033[0m:"
        echo -e "1 - 仅计算大小"
        echo -e "\033[32m2 - 拷贝全部文件(默认选项)\033[0m"
        echo -e "3 - 仅拷贝音频文件"

        # 使用 read 命令等待用户输入，设置超时为5秒
        read -p "请输入数字: "  c_uc_input

        # 检查用户是否提供了输入
        if [[ -z "$c_uc_input" ]]; then
            # 如果变量为空（即没有输入），说明超时已发生
        	echo
            echo -e "默认选择\033[32m拷贝全部文件\033[0m"
            Only_Volume_Calculate_Flag=0
        else
            # 用户输入了内容，根据输入赋值旗标
            case $c_uc_input in
                1)
                    Only_Volume_Calculate_Flag=1
                    echo -e "\033[33m你选择仅计算大小\033[0m"
                    ;;
                2)
                    Only_Volume_Calculate_Flag=0
                    echo -e "你选择了\033[32m拷贝全部文件\033[0m"
                    ;;
                3)
                    Only_Volume_Calculate_Flag=0
                    FatherAudioOrAll=audio
                    echo -e "你选择了\033[32m仅拷贝音频文件\033[0m"
                    ;;
                *)
                    echo
        			echo -e "无效的输入，将采取\033[32m拷贝全部文件\033[0m"
                    ;;
            esac
        fi

        
}

force_copy_wait(){
        echo -e "请输入数字选择是否覆盖已经存在的文件:"
        echo -e "1 - 覆盖文件"
        echo -e "2 - 跳过文件"

        # 使用 read 命令等待用户输入，设置超时为5秒
        read -p "请输入数字: "  f_n_input

        # 检查用户是否提供了输入
        if [[ -z "$f_n_input" ]]; then
            # 如果变量为空（即没有输入），说明超时已发生
        	echo
            echo -e "默认选择\033[32m跳过文件\033[0m"
            Force_Copy_Flag=0
        else
            # 用户输入了内容，根据输入赋值旗标
            case $f_n_input in
                1)
                    Force_Copy_Flag=1
                    echo -e "你选择覆盖已存在文件"
                    ;;
                2)
                    Force_Copy_Flag=0
                    echo -e "你选择跳过已存在文件"
                    ;;
                *)
                    echo
        			echo -e "无效的输入，将跳过已存在文件"
                    Force_Copy_Flag=0
                    ;;
            esac
        fi
        
}
# 注意：这个脚本可能需要根据你的系统和磁盘的具体情况进行调整。
# 上述函数中的操作可以根据实际需求进行修改和扩展。
clear
IFxmlFileList="`ls | grep -E '\.xml|\.fcpxml|\.fcpxmld'`" 
disk_copy_space_found=0
#统计xml文件数量
XMLNum=0
while read XmlFile;do
        if [[ "$XmlFile" == *.xml ]] || [[ "$XmlFile" == *.fcpxml ]] || [[ "$XmlFile" == *.fcpxmld ]];then
                
                let XMLNum++
                if disk_copy_check_input_params "${XmlFile}" ; then
                echo "${XmlFile}"
                else
                let disk_copy_space_found++
                fi
        else
                true
        fi
done <<< "$(echo "$IFxmlFileList")"

#未发现xml文件
if [[ "$XMLNum" == 0 ]] ;then
        clear
        echo -e "\033[31m未发现任何可用xml文件，请将xml文件放入此文件夹中\033[0m"
        exit 8
else
        #发现xml文件
        echo '************请注意当前文件夹内有以上' $XMLNum '个xml文件************'
        echo
        if [[ "${disk_copy_space_found}" == 0 ]];then
            :
        else
            echo -e "\033[31m该文件夹内xml文件名有空格或斜杠，请检查后重新运行本程序\033[0m"
            exit
        fi
        # 显示提示信息
        only_calc_wait
        clear


        if [[ ${Only_Volume_Calculate_Flag} == 1 ]];then
            true
        else
            #echo 将拷贝文件            
            select_external_disks
            clear
            force_copy_wait
            clear
            #echo diskis$Dest_Path_Input
        fi
        #开始拷贝
        
        
        


        
                
                       
       if [[ ${Only_Volume_Calculate_Flag} == 1 ]];then
           #echo 仅计算大小
           bash ~/${CoreFileProcess} c `echo $IFxmlFileList`
           read -p "程序运行完毕按任意键退出"  ExitOrNot_input
          
       else
           
           echo "你选择的硬盘是：$Dest_Path_Input"
           echo 将拷贝文件
           if [[ ${Force_Copy_Flag} == 1 ]];then
               FatherForceCopyOrNot=f
               echo 强制覆盖
           else
               FatherForceCopyOrNot=n
               echo 跳过文件
           fi

           if [[ ${FatherDisk_To_Disk_Flag} == 1 ]];then
               echo 硬盘对硬盘
               FatherDiskOrNot=dd
           else
               echo 硬盘对路径
               FatherDiskOrNot=ndd
           fi
           bash ~/${CoreFileProcess} ${FatherForceCopyOrNot} no uc ${FatherAudioOrAll} ${FatherDiskOrNot} "$Dest_Path_Input" `echo $IFxmlFileList`
           read -p "程序运行完毕按任意键退出"  ExitOrNot_input
       fi
       echo -ne "\r              \r"
       echo
       echo -ne "\r              \r"
   
                        
               
        
#发现xml文件循环结束
fi

echo -e "\033[32m程序退出\033[0m"