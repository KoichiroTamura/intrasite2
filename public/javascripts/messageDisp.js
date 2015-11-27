/*-----------------------------------------------------------------*
 *-----------------------------------------------------------------*
 【ファイル概要】メッセージ表示
 【目的役割】メッセージ表示に関するロジックを定義する。
 *-----------------------------------------------------------------*
 *-----------------------------------------------------------------*/

/*-----------------------------------------------------------------*
 【機能概要】メッセージ・チェックボックス操作
 【入力引数】操作タイプ
 【戻り値】正常：true　例外：false
 【目的役割】メッセージのチェックボックス操作を行う。
 *-----------------------------------------------------------------*/
function messageSelect(type){
	var		che_obj;										// チェックボックス
	var		bg_obj;											// 背景表示ボックス
	var		jdg_obj;										// ＯＮ・ＯＦＦ判定
	var		count;
	var		set_param;
	var		str_img;
	
	count = 1;
	che_obj = document.getElementById("message" + count);
	
	while (null != che_obj) {								// メッセージ・チェックボックス数ループ
		/* チェックＯＮ・ＯＦＦ判定 */
		switch (type) {
		case "all_true":									// 全てＯＮモード
			set_param = 1;
			break;
		case "all_false":									// 全てＯＦＦモード
			set_param = 0;
			break;
		case "open":										// 既読のみＯＮモード
			jdg_obj = document.getElementById("message_open_unopen" + count);
			if (jdg_obj.value == "既読") {
				set_param = 1;
			}
			else{
				set_param = 0;
			}
			break;
		case "unopen":										// 未読のみＯＮモード
			jdg_obj = document.getElementById("message_open_unopen" + count);
			if (jdg_obj.value == "未読") {
				set_param = 1;
			}
			else{
				set_param = 0;
			}
			break;
		defalt:												// 例外
			set_param = 0;
			break;
		}
		
		/* チェックＯＮ・ＯＦＦ操作 */
		if (1 == set_param) {								// チェックボックスＯＮ
			che_obj.checked = true;
			bg_obj = document.getElementById("messageBgDisp" + count);
			if (null != bg_obj) {
				str_img = 'transparent url("/images/t_MainInfoFrame01.gif") repeat-x scroll center center;'
				bg_obj.style.background = str_img;
			}
			else{
				return false;
			}
		}
		else{												// チェックボックスＯＦＦ
			che_obj.checked = false;
			reMessageBgDisp(count);
		}
		
		count++;											// 次のチェックボックス
		che_obj = document.getElementById("message" + count);
		
		if (count > 10000) {								// 無限ループプロテクト：１万ループ
			break;
		}
	}
	
	return true;
}

/*-----------------------------------------------------------------*
 【機能概要】メッセージ背景表示
 【入力引数】メッセージ番号
 【戻り値】正常：true　例外：false
 【目的役割】メッセージの背景画像を表示する。
 *-----------------------------------------------------------------*/
function reMessageBgDisp(x)
{
	var		obj;
	var		jdg_obj_open;							// 既読／未読
	var		jdg_obj_pri;							// 重要度
	var		str_img;
	var		num;
	
	obj = document.getElementById("messageBgDisp" + x);
	jdg_obj_open = document.getElementById("message_open_unopen" + x);
	jdg_obj_pri = document.getElementById("message_priority" + x);
	
	if ((null != obj) && (null != jdg_obj_open) && (null != jdg_obj_pri)) {
		if (3 < jdg_obj_pri.value) {				// 重要度がHigh以上
			num = 2;
		}
		else if (jdg_obj_open.value == "未読") {	// 未読
			num = 3;
		}
		else{										// 標準
			num = 4;
		}
		
		str_img = 'transparent url("/images/t_MainInfoFrame0' + num + '.gif") repeat-x scroll center center;'
		obj.style.background = str_img;
	}
	else{
		return false;
	}
	
	return true;
}
