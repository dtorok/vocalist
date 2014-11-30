function JsonRPC(host, defaultError, defaultSuccess)
{
    this.host = host;
    this.defaultSuccess = defaultSuccess;
    this.defaultError = defaultError;

    this.requestId = 1;
}

JsonRPC.prototype.call = function(method, params, onSuccess, onError)
{
    var rpc = this;
    $.ajax(this.host, {
        type: 'POST',
        async: true,
        dataType: 'json',
        contentType: 'application/json',
        data: JSON.stringify({'id': this.requestId++, 'method': method, 'params': params}),
        cache: false,
        processData: false,
        'success': function(data) {
            if (data.error == null)
                rpc.onSuccess(onSuccess, data.result);
            else
                rpc.onError(onError, data.error);
        },
        'error': function(r, errorString) {
            rpc.onError(onError, errorString);
        }});
}

JsonRPC.prototype.onSuccess = function (cb, result)
{
    if (cb)
        cb(result);
    else if (this.defaultSuccess)
        this.defaultSuccess(result);
}

JsonRPC.prototype.onError = function (cb, error)
{
    if (cb)
        cb(error);
    else if (this.defaultError)
        this.defaultError(error);
}