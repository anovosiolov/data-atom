URL = require 'url'

sql = require 'mssql'
_s = require 'underscore.string'

DataManager = require './data-manager'

module.exports =
class SqlServerManager extends DataManager
   constructor: (url) ->
      super(url)
      urlObj = URL.parse(url)

      @config = {
         user: urlObj.auth.split(':')[0],
         password: urlObj.auth.split(':')[1],
         server: urlObj.hostname, # You can use 'localhost\\instance' to connect to named instance
         database: _s.ltrim(urlObj.pathname, '/')
      }
      if urlObj.port
         @config.port = urlObj.port

   buildError: (err) ->
      'Error (' + err.code + ') - ' + err.message

   execute: (query, onSuccess, onError) =>
      connection = new sql.Connection @config, (err) =>
         if err
            console.error(err)
            onError(@buildError(err))
            return

         # Query

         request = connection.request()
         request.query query, (err, recordset) =>
            if err
               console.error(err)
               onError(@buildError(err))
               return

            console.log(recordset)
            callOnSuccess(recordset, onSuccess)

   # conver the results into what we expect so the UI doens't have to handle all different result types
   callOnSuccess: (result, onSuccess) ->
      #console.log result
      if results.command != 'SELECT'
         onSuccess { message: @buildMessage(results), command: result.command, fields: result.fields, rowCount: result.rowCount, rows: result.rows }
      else
         onSuccess { command: result.command, fields: result.fields, rowCount: result.rowCount, rows: result.rows }

   buildMessage: (results) ->
      switch results.command
         when 'UPDATE' then results.rowCount + ' rows updated.'
         when 'DELETE' then results.rowCount + ' rows deleted.'
         else JSON.stringify(results)
