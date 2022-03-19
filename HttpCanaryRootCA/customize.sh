SKIPUNZIP=0
ASH_STANDALONE=1

ui_print '========================================================'
ui_print '  模块说明：'
ui_print '    Android 11收紧了APP安装系统CA证书的权限，只能用户手动安装。'
ui_print '    而HttpCanary长期未更新，未对此适配，导致不能正常安装CA证书。'
ui_print '    故制作一个Magisk模块，方便安装。'
ui_print '========================================================'

if (( $API < 30 )) ; then
    ui_print "  你的系统低于安卓11，可通过授予root权限手动安装CA证书，不必使用本模块。"
    ui_print "  是否继续安装模块？按 音量+ 则继续，按 音量- 则取消安装。"
    while :; do
        choice="$(getevent -qlc 1 | awk '{ print $3 }')"
        if [ $choice = "KEY_VOLUMEUP" ] ; then
            ui_print "  你选择了继续安装!"
            break
        elif [ $choice = "KEY_VOLUMEDOWN" ] ; then
            abort "  你选择了取消安装！"
        fi
    done  
fi

hcname="com.guoshi.httpcanary"
[ -z "$(pm list packages $hcname)" ] && abort "  你还没有安装HttpCanary,请先安装此应用！"

hcdata=/data/data/$hcname
if [ -d ${hcdata}.premium ] ; then
    if [ -d $hcdata ] ; then
        ui_print "  你好像同时安装了HttpCanary普通版和高级版。"
        ui_print "  然而接下来将只为高级版安装CA证书。"
    fi
    hcdata=${hcdata}.premium
fi

pemFile=${hcdata}/cache/HttpCanary.pem
if [ ! -f $pemFile ] ; then
    ui_print "  HttpCanary还没有生成CA证书。"
    ui_print "  请打开HttpCanary，完成初始设置。"
    ui_print "  并完成最后一步的 安装根证书。"
    ui_print "  当然了，这并不会安装成功。"
    ui_print "  但是，这一步能够生成证书。"
    ui_print "  如果已经运行过app，请到app设置里尝试安装根证书"
    ui_print "  当然，这一步也不会成功，但能生成证书。"
    ui_print "  然后重新安装本模块。"
    abort "  ------已终止本次模块安装！------"
fi

# subject_hash 
# openssl x509 -inform PEM -subject_hash_old -in HttpCanary.pem
# 87bc3517

mkdir -p $MODPATH/system/etc/security/cacerts
cp $pemFile $MODPATH/system/etc/security/cacerts/87bc3517.0

uid=$(ls -l "$pemFile" | awk '{ print $3 }')
#空文件会导致卸载残留
jksFile=$hcdata/cache/HttpCanary.jks
echo 1 > $jksFile
set_perm $jksFile $uid ${uid}_cache 0600

ui_print "  模块安装完毕，重启后生效。"
ui_print "  注意：请勿【卸载HttpCanary】或【清除HttpCanary的数据】。"
ui_print "  否则需要重新安装本模块。"

# 默认权限请勿删除
set_perm_recursive $MODPATH 0 0 0755 0644
