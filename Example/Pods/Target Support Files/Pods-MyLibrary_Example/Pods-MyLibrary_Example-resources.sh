#!/bin/sh
set -e
set -u
set -o pipefail

function on_error {
  echo "$(realpath -mq "${0}"):$1: error: Unexpected failure"
}
trap 'on_error $LINENO' ERR

if [ -z ${UNLOCALIZED_RESOURCES_FOLDER_PATH+x} ]; then
  # If UNLOCALIZED_RESOURCES_FOLDER_PATH is not set, then there's nowhere for us to copy
  # resources to, so exit 0 (signalling the script phase was successful).
  exit 0
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

XCASSET_FILES=()

# This protects against multiple targets copying the same framework dependency at the same time. The solution
# was originally proposed here: https://lists.samba.org/archive/rsync/2008-February/020158.html
RSYNC_PROTECT_TMP_FILES=(--filter "P .*.??????")

case "${TARGETED_DEVICE_FAMILY:-}" in
  1,2)
    TARGET_DEVICE_ARGS="--target-device ipad --target-device iphone"
    ;;
  1)
    TARGET_DEVICE_ARGS="--target-device iphone"
    ;;
  2)
    TARGET_DEVICE_ARGS="--target-device ipad"
    ;;
  3)
    TARGET_DEVICE_ARGS="--target-device tv"
    ;;
  4)
    TARGET_DEVICE_ARGS="--target-device watch"
    ;;
  *)
    TARGET_DEVICE_ARGS="--target-device mac"
    ;;
esac

install_resource()
{
  if [[ "$1" = /* ]] ; then
    RESOURCE_PATH="$1"
  else
    RESOURCE_PATH="${PODS_ROOT}/$1"
  fi
  if [[ ! -e "$RESOURCE_PATH" ]] ; then
    cat << EOM
error: Resource "$RESOURCE_PATH" not found. Run 'pod install' to update the copy resources script.
EOM
    exit 1
  fi
  case $RESOURCE_PATH in
    *.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}" || true
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.xib)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}" || true
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.framework)
      echo "mkdir -p ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}" || true
      mkdir -p "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" $RESOURCE_PATH ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}" || true
      rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH"`.mom\"" || true
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd\"" || true
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd"
      ;;
    *.xcmappingmodel)
      echo "xcrun mapc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm\"" || true
      xcrun mapc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm"
      ;;
    *.xcassets)
      ABSOLUTE_XCASSET_FILE="$RESOURCE_PATH"
      XCASSET_FILES+=("$ABSOLUTE_XCASSET_FILE")
      ;;
    *)
      echo "$RESOURCE_PATH" || true
      echo "$RESOURCE_PATH" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
if [[ "$CONFIGURATION" == "Debug" ]]; then
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_down_red.imageset/cashier_arrow_down_red@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_down_red.imageset/cashier_arrow_down_red@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_down_red.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_black.imageset/cashier_arrow_right_black@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_black.imageset/cashier_arrow_right_black@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_black.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_white.imageset/cashier_arrow_right_white@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_white.imageset/cashier_arrow_right_white@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_white.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_no_round.imageset/cashier_check_no_round@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_no_round.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_round.imageset/cashier_check_round@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_round.imageset/cashier_check_round@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_round.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_dark.imageset/cashier_close_roundSmall_dark@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_dark.imageset/cashier_close_roundSmall_dark@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_dark.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_gray.imageset/cashier_close_roundSmall_gray@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_gray.imageset/cashier_close_roundSmall_gray@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_gray.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_dark.imageset/cashier_close_round_dark@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_dark.imageset/cashier_close_round_dark@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_dark.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_gray.imageset/cashier_close_round_gray@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_gray.imageset/cashier_close_round_gray@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_gray.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_yellow.imageset/cashier_close_round_yellow@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_yellow.imageset/cashier_close_round_yellow@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_yellow.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_free_mark.imageset/cashier_free_mark.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_free_mark.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_free_mark_selected.imageset/cashier_free_mark_selected.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_free_mark_selected.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_friendpay_share_default.imageset/cashier_friendpay_share_default@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_friendpay_share_default.imageset/cashier_friendpay_share_default@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_friendpay_share_default.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_graduallyPay_guide.imageset/cashier_graduallyPay_guide@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_graduallyPay_guide.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_gradually_button.imageset/cashier_gradually_button@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_gradually_button.imageset/cashier_gradually_button@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_gradually_button.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_honeyPay_guide.imageset/cashier_honeyPay_guide@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_honeyPay_guide.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdLoading_circle.imageset/cashier_jdLoading_circle@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdLoading_circle.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdLoading_icon.imageset/cashier_jdLoading_icon@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdLoading_icon.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdpay_logo.imageset/cashier_jdpay_logo.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdpay_logo.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_notification_icon.imageset/cashier_notification_icon@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_notification_icon.imageset/cashier_notification_icon@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_notification_icon.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_sale_mark.imageset/cashier_sale_mark.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_sale_mark.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_sale_mark_selected.imageset/cashier_sale_mark_selected.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_sale_mark_selected.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDTestViewViewController.xib"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_down_red.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_black.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_white.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_no_round.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_round.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_dark.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_gray.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_dark.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_gray.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_yellow.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_free_mark.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_free_mark_selected.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_friendpay_share_default.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_graduallyPay_guide.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_gradually_button.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_honeyPay_guide.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdLoading_circle.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdLoading_icon.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdpay_logo.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_notification_icon.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_sale_mark.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_sale_mark_selected.imageset"
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_down_red.imageset/cashier_arrow_down_red@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_down_red.imageset/cashier_arrow_down_red@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_down_red.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_black.imageset/cashier_arrow_right_black@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_black.imageset/cashier_arrow_right_black@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_black.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_white.imageset/cashier_arrow_right_white@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_white.imageset/cashier_arrow_right_white@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_white.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_no_round.imageset/cashier_check_no_round@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_no_round.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_round.imageset/cashier_check_round@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_round.imageset/cashier_check_round@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_round.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_dark.imageset/cashier_close_roundSmall_dark@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_dark.imageset/cashier_close_roundSmall_dark@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_dark.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_gray.imageset/cashier_close_roundSmall_gray@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_gray.imageset/cashier_close_roundSmall_gray@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_gray.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_dark.imageset/cashier_close_round_dark@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_dark.imageset/cashier_close_round_dark@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_dark.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_gray.imageset/cashier_close_round_gray@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_gray.imageset/cashier_close_round_gray@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_gray.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_yellow.imageset/cashier_close_round_yellow@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_yellow.imageset/cashier_close_round_yellow@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_yellow.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_free_mark.imageset/cashier_free_mark.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_free_mark.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_free_mark_selected.imageset/cashier_free_mark_selected.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_free_mark_selected.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_friendpay_share_default.imageset/cashier_friendpay_share_default@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_friendpay_share_default.imageset/cashier_friendpay_share_default@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_friendpay_share_default.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_graduallyPay_guide.imageset/cashier_graduallyPay_guide@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_graduallyPay_guide.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_gradually_button.imageset/cashier_gradually_button@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_gradually_button.imageset/cashier_gradually_button@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_gradually_button.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_honeyPay_guide.imageset/cashier_honeyPay_guide@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_honeyPay_guide.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdLoading_circle.imageset/cashier_jdLoading_circle@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdLoading_circle.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdLoading_icon.imageset/cashier_jdLoading_icon@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdLoading_icon.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdpay_logo.imageset/cashier_jdpay_logo.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdpay_logo.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_notification_icon.imageset/cashier_notification_icon@2x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_notification_icon.imageset/cashier_notification_icon@3x.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_notification_icon.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_sale_mark.imageset/cashier_sale_mark.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_sale_mark.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_sale_mark_selected.imageset/cashier_sale_mark_selected.png"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_sale_mark_selected.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/Contents.json"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDTestViewViewController.xib"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_down_red.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_black.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_arrow_right_white.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_no_round.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_check_round.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_dark.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_roundSmall_gray.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_dark.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_gray.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_close_round_yellow.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_free_mark.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_free_mark_selected.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_friendpay_share_default.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_graduallyPay_guide.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_gradually_button.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_honeyPay_guide.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdLoading_circle.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdLoading_icon.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_jdpay_logo.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_notification_icon.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_sale_mark.imageset"
  install_resource "${PODS_ROOT}/../../MyLibrary/Assets/JDCashier.xcassets/cashier_sale_mark_selected.imageset"
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [[ "${ACTION}" == "install" ]] && [[ "${SKIP_INSTALL}" == "NO" ]]; then
  mkdir -p "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ "`xcrun --find actool`" ] && [ -n "${XCASSET_FILES:-}" ]
then
  # Find all other xcassets (this unfortunately includes those of path pods and other targets).
  OTHER_XCASSETS=$(find "$PWD" -iname "*.xcassets" -type d)
  while read line; do
    if [[ $line != "${PODS_ROOT}*" ]]; then
      XCASSET_FILES+=("$line")
    fi
  done <<<"$OTHER_XCASSETS"

  if [ -z ${ASSETCATALOG_COMPILER_APPICON_NAME+x} ]; then
    printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  else
    printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" --app-icon "${ASSETCATALOG_COMPILER_APPICON_NAME}" --output-partial-info-plist "${TARGET_TEMP_DIR}/assetcatalog_generated_info_cocoapods.plist"
  fi
fi
