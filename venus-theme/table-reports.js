// Licensed to the Apache Software Foundation (ASF) under one or more
// contributor license agreements.  See the NOTICE file distributed with
// this work for additional information regarding copyright ownership.
// The ASF licenses this file to You under the Apache License, Version 2.0
// (the "License"); you may not use this file except in compliance with
// the License.  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

function percentage(input_str) {
  return Number(input_str).toFixed(2);
}
function strip_package(input_str) {
  return input_str.replace(/.*\.([^.]+)/, "$1");
}
function suiteHeaderFilter(headerValue, rowValue, rowData, filterParams) {
  //headerValue - the value of the header filter element
  //rowValue - the value of the column in this row
  //rowData - the data for the row being filtered
  //filterParams - params object passed to the headerFilterFuncParams property

  // javascript booleans are confusing, use strings for simpler debugging
  return ("both" == headerValue ||
          ("suite" == headerValue && rowValue) ||
          ("method" == headerValue && ! rowValue));
}
function percentageToolTip(cell) {
  return percentage(cell.getValue()) + "% (" + cell.getData().failures + "/" + cell.getData().runs + ")"
}

function detailDialog(row_data) {
  var method_suffix = (row_data.suite ? '' : ('.' + row_data['method']));
  var title = strip_package(row_data['class']) + method_suffix;

  $( "#row-details-class" ).html(row_data['class']);
  $( "#row-details-method" ).html(row_data['method']);
  $( "#row-details-has-method" ).toggle( ! row_data.suite );
  $( "#row-details-failrate" ).html(percentage(row_data['fail_rate']) + "%");
  $( "#row-details-fails" ).html(row_data['failures']);
  $( "#row-details-runs" ).html(row_data['runs']);
  $( "#row-details-jobs" ).html('');
  $.each(row_data['failed_jobs'], function(index, value) {
    $( "#row-details-jobs" ).append("<li><a href=\"job-data/"+value+"\">" + value + "</a></li>");
  });
  $( "#row-details-dialog-box" ).show().dialog({
    title:title,
    minWidth: window.innerWidth * 0.5, // must be number, can't use '50vw'
    minHeight: window.innerHeight * 0.3, // must be number, can't use '30vh'
    maxHeight: window.innerHeight * 0.8, // must be number, can't use '80vh'
    modal:true,
  });
}


$(document).ready(function() {
  $("#failure-rates-table").tabulator({
    height:"80vh", // set height of table (in CSS or here), this enables the Virtual DOM and improves render speed dramatically (can be any valid css height value)
    layout:"fitDataFill",
    columnVertAlign:"bottom",
    columns:[ //Define Table Columns
      {title:"Test",
       columns:[
         {title:"Suite?", field:"suite", formatter: "tick",
          editor:"select",
          headerFilter:true, headerFilterParams:{"both":"Both","suite":"Suite", "method":"Method"},
          headerFilterPlaceholder:"both", headerFilterFunc:suiteHeaderFilter,
         },
         {title:"Class", field:"class", headerFilter:"input", minWidth:"300",
          formatter: function(cell, formatterParams) {
            return strip_package(cell.getValue());
          },
          tooltip: function(cell) {
            return cell.getValue();
          } },
         {title:"Method", field:"method", headerFilter:"input", minWidth:"200" } ] },
      {title:"Fail Rate",
       columns:[
         {title:"%", field:"fail_rate", align:"right", sorter:"number",
          download:false, // already downloadable as 'Rate' below
          formatter: function(cell,formatterParams) {
            return percentage(cell.getValue());
          },
          tooltip: percentageToolTip
         },
         {title:"Rate", field:"fail_rate", align:"right", minWidth:"200",
          sorter:"number", formatter:"progress",
          formatterParams: {color:['#b28050','#f5e100','orange','red']},
          tooltip: percentageToolTip
          } ] },
      {title:"Run Totals",
       columns:[
         {title:"Runs", field:"runs", sorter:"number", align:"right" },
         {title:"Fails", field:"failures", sorter:"number", align:"right" } ] }
    ],
    rowClick:function(clickEvent, row) {
      detailDialog(row.getData());
    },
  });
  $('#failure-rates-table-selector').change(function() {
    var file = $("select").val();
    $("#failure-rates-table").tabulator("setData","./reports/" + file);
  });
  $('#failure-rates-table-selector').change();
  $('#download-button').click(function(){
    $('#failure-rates-table').tabulator("download", "csv", "failure-rates-data.csv");
  }); 
  $('#failure-rates-controls').show();
});
