/**
 * AjaxUpload
 * formとは独立にファイルアップロードを行うスクリプト
 */
'use strict';


function Uploader(elem) {
    this.elem = $(elem);
    this.registerFileChange();
    this.registerDrag();
    this.updateState();
}
Uploader.prototype = {
    elem: null,
    area: null,
    accept: null,
    maxCount: 0,
    maxFileSize: 0,
    input: null,
    inputType: null,
    hiddenName: null,
    uploadingCount: 0,
    form: null,

    /**
     * <input type=file>のイベントを追加する
     */
    registerFileChange: function() {
        var ipt = this.elem.find('input:file');
        ipt.on('change', this.onFileChange.bind(this));
        this.input = ipt;
        this.form = this.elem.find('form');
        this.accept = ipt.attr('accept');
    },
    /**
     * イベント受け入れ状態を更新する
     */
    updateState: function() {
        if (this.uploadingCount) {
            this.input.prop('disabled', true);
            this.area.addClass('disabled');
        } else {
            this.input.prop('disabled', false);
            this.area.removeClass('disabled');
        }
    },
    /**
     * ファイル選択イベント
     * @param Event e
     */
    onFileChange: function(e) {
        this.processFiles(this.input[0].files);
    },
    /**
     * ファイルを削除する
     */
    clearFiles: function() {
        this.input[0].value = '';
        this.uploadingCount = 0;
    },
    /**
     * ドラッグ&ドロップのイベントを追加する
     */
    registerDrag: function() {
        var dragArea = this.elem.find('.drag-area');
        dragArea.on('drop', this.onDrop.bind(this))
                .on('dragover', this.onDragOver.bind(this))
                .on('dragleave', this.onDragLeave.bind(this));
        this.area = dragArea;
    },
    /**
     * ドラッグ＆ドロップのイベントを消費する
     * @param Event e
     * @param bool hover
     */
    consume: function(e, hover) {
        e.stopPropagation();
        e.preventDefault();
        if (hover) {
            this.area.addClass('hover');
        } else {
            this.area.removeClass('hover');
        }
        return false;
    },
    /**
     * アップロード済みの数とアップロード中の数の合計
     */
    filesCount: function() {
        var values = this.elem.find('.fieldinput-' + this.inputType + '-value:not(.deleted-value)');
        return values.length + this.uploadingCount;
    },
    /**
     * アップロード数制限を超えている
     */
    isOver: function() {
        return this.maxCount && this.maxCount < this.filesCount();
    },
    /**
     * ファイルが選択されたのでアップロードする
     * @param Array files
     */
    processFiles: function(files) {
        if (!files || this.uploadingCount) {
            return;
        }
        var up = this;
        var promisses = [];
        $.each(files, function(i, file) {
          promisses.push(up.upload(file));
        });
        this.updateState();
        $.when(promisses).done(function() {
            setTimeout(function() {
                up.updateState();
                up.clearFiles();
            }, 50);
        });
    },
    /**
     * ドロップイベント
     * @param Event e
     */
    onDrop: function(e) {
        var oe = e.originalEvent;
        var files = oe.dataTransfer && oe.dataTransfer.files;
        this.processFiles(files);
        return this.consume(e);
    },
    /**
     * ドラッグイベント
     * @param Event e
     */
    onDragOver: function(e) {
        return this.consume(e, true);
    },
    /**
     * ドラッグアウトイベント
     * @param Event e
     */
    onDragLeave: function(e) {
        return this.consume(e);
    },
    /**
     * アップロード実行
     * @param File file
     */
    upload: function(file) {
        var up = this;
        var progress = $('<div class="ajaxupload-progress"></div>');
        progress.text(file.name);
        progress.append('<span class="ajaxupload-proginfo"></span>');
        var bar = $('<div class="ajaxupload-progbar">.</div>');
        progress.append(bar);
        this.elem.append(progress);
        if (this.maxFileSize && file.size > this.maxFileSize) {
            this.onUploadError(progress, null, null,
                'Too large upload size:(' + file.size + ' bytes > ' + this.maxFileSize + ' bytes)');
            return new $.Deferred().resolve().promise();
        } else if (this.accept && this.accept.indexOf(file.type) < 0) {
            this.onUploadError(progress, null, null,
                'Unacceptable type:(' + file.type + ')');
            return new $.Deferred().resolve().promise();
        }
        this.uploadingCount++;
        var data = new FormData();
        data.append('file', file, file.name);
        var url = up.form.attr('action');
        var ajax = $.ajax(url, {
            xhr: function() {
                var xhr = new XMLHttpRequest();
                var xup = xhr.upload;
                if (!xup) {
                    throw 'XMLHttpRequest.upload not supported.';
                }
                xup.addEventListener('progress', up.onUploadProgress.bind(up, xhr, progress));
                xup.addEventListener('abort', up.onUploadAbort.bind(up, xhr, progress));
                return xhr;
            },
            type: 'POST',
            processData: false,
            contentType: false,
            dataType: 'text',
            data: data,
            success: up.onUploadSuccess.bind(up, progress),
            error: up.onUploadError.bind(up, progress),
            complete: up.onUploadComplete.bind(up, progress)
        });
        return ajax;
    },
    /**
     * アップロード途中
     * @param {XMLHttpRequest} xhr
     * @param {jQuery} progress
     * @param {Event} e
     */
    onUploadProgress: function(xhr, progress, e) {
        var pc = parseInt(e.loaded / e.total * 100);
        progress.find('span').text('(' + pc + '%)');
        progress.find('.ajaxupload-progbar').css('width', pc + '%');
    },
    /**
     * アップロード中断
     * @param {XMLHttpRequest} xhr
     * @param {jQuery} progress
     * @param {Event} e
     */
    onUploadAbort: function(xhr, progress, e) {

    },
    /**
     * アップロード終了時の処理
     * @param {XMLHttpRequest} xhr
     * @param {jQuery} progress
     * @param {Event} e
     */
    onUploadSuccess: function(progress, data) {
        progress.find('span').text('Success.');
        setTimeout(function() {
            progress.fadeOut('slow', function() {
                progress.remove();
            });
        }, 1000);
    },
    /**
     * エラー時の処理
     * @param {jQuery} progress
     * @param {XMLHttpRequest} xhr
     * @param {String} status
     * @param {Exception} error
     */
    onUploadError: function(progress, xhr, status, error) {
        progress.find('span').text('Fail. : ' + error);
        setTimeout(function() {
            progress.fadeOut('slow', function() {
                progress.remove();
            });
        }, 3000);
    },
    /**
     * アップロード完了時
     * @param {jQuery} progress
     * @param {XMLHttpRequest} xhr
     */
    onUploadComplete: function(progress, xhr) {
        this.uploadingCount--;
        if (this.uploadingCount < 0) {
            this.uploadingCount = 0;
        }
        this.updateState();
    }
};

Uploader.regist = function($elem) {
  if (window.File && window.FileList && window.FileReader) {
    new Uploader($elem);
    $elem.find('form').submit(function(e) {
      e.preventDefault();
      return false;
    });
  } else {
    $elem.find('.drag-area').removeClass('drag-area');
  }
}
