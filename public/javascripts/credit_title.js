function credit_title(){
		new Effect.SlideDown("credit_title", { 
		        from:3, // 開始時透明度 
		        to:0.0, // 終了時透明度 
		        delay:3, // 開始までの秒数 
		        fps:120, // フレームレート 
		        duration: 20, // アニメーションする時間(秒) 
		        beforeStartInternal: function(effect) {
		        }, 
		        afterFinishInternal: function(effect) { 
					Element.hide("credit_title"); 
		        } 
		   }); 

};
