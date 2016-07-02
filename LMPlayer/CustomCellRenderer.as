// Copyright (c) 2012 Kyoto University and DoGA
package {
	import fl.controls.listClasses.CellRenderer;
	import flash.display.*;
	import flash.text.TextFormat;
	import flash.filters.BevelFilter;
	import flash.events.*;
	
	/**
	 * しおりリストの書式に使用するカスタムセルレンダラークラス。スキンでは背景しか設定できないので、文字色の変更のために使用する。
	 */
	public class CustomCellRenderer extends CellRenderer {
		/** 非選択セルのテキストの書式 */
		protected var normalFormat:TextFormat = new TextFormat();
		/** 選択セルのテキストの書式 */
		protected var selectedFormat:TextFormat = new TextFormat();
		/** テキストのサイズ */
		public static const ROW_TEXT_SIZE:Number = 12;
		/** パディング */
		protected const ROW_TEXT_PADDING:Number = 5;
		/** スライダが動いて選択が無効になった時のセルの背景 */
		protected var invalidSkin:MovieClip = new CellRenderer_selectedInvalidSkin();
		
		/**
		 * コンストラクタ.
		 */
        public function CustomCellRenderer() { 
			normalFormat.size = ROW_TEXT_SIZE;
			normalFormat.color = 0;
			selectedFormat.size = ROW_TEXT_SIZE;
			selectedFormat.color = 0xffffff;
            setStyle("textFormat", normalFormat); 
			setStyle("textPadding", ROW_TEXT_PADDING);
        }
		
		/**
		 * 現在のセルが選択されているかどうかを示すブール値。値の設定と同時に文字の書式を設定する。
		 */
		override public function set selected(value:Boolean):void
		{
			if (value) {
				super.setStyle("textFormat", selectedFormat);
			} else {
				super.setStyle("textFormat", normalFormat);
			}
			super.selected = value;
		}
		
		/**
		 * スタイルの設定
		 * 
		 * @param	style	スタイルプロパティの名前
		 * @param	value	スタイルの値
		 */
		override public function setStyle(style:String, value:Object):void
		{
			if (style == "selectedUpSkin") {
				if ((!selected || (data != null && data.hasOwnProperty("invalid") && data.invalid == true))) {
					super.setStyle("textFormat", normalFormat);
				} else {
					super.setStyle("textFormat", selectedFormat);
				}
			}
			super.setStyle(style, value);
		}
    } 
}