#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

get '/' => sub ($c) {
  $c->render(template => 'index');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'loan';
<div>
<label for="P">贷（单位：万）:</label>
<input type="text" id="P" name="P" value="50"/>
<select id="P_select"></select>
</div>

<div>
<label for="r">年利率（单位：%）:</label>
<input type="text" id="r" name="r" value="3.1"/>
<select id="r_select"></select>
</div>

<div>
<label for="N">期（单位：月）:</label>
<input type="text" id="N" name="N" value="240"/>
<select id="N_select"></select>
</div>

<div>
<input type="radio" id="type1" name="type" value="1" checked>
<label for="type1">等额本息</label>
<input type="radio" id="type2" name="type" value="2">
<label for="type2">等额本金</label>
</div>
<div>
<button name="button" onclick="calc()">计算</button>
<button name="button" onclick="accumulate()">组合贷款</button>
<button name="button" onclick="clear_accumulate()">清空</button>
<button id="export-btn">导出csv</button>

</div>

<div id='accumulate_info'>

</div>


<div id="content">
  <table id="table">
    
  </table>
</div>
<div id="fixedButtons">
  <button id="scrollToTopBtn">&#x25B2;</button>
  <button id="scrollToMiddleBtn">&nbsp;</button>
  <button id="scrollToBottomBtn">&#x25BC;</button>
</div>


<style>
table {
  border-collapse: collapse; /* 合并边框，使分割线看起来更平滑 */
  
}
td, th {
  border: 1px solid black; /* 设置单元格边框样式为实线，可以根据需要调整宽度和颜色 */
  padding: 3px; /* 设置单元格内边距，增加内容与边框的间距 */
}

.selected {
  background-color: yellow !important; /* 设置选中行的背景颜色 */
}

#fixedButtons {
  position: fixed;
  bottom: 20px;
  right: 20px;
  display: flex;
  flex-direction: column;
}

#fixedButtons button {
  font-size: 20px;
  width: 40px;
  height: 40px;
  margin-bottom: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}

</style>

<script>
  var accumulate_arrs = [];
  function accumulate() {
    $("#accumulate_info").empty();
    $("#table").empty();
    let P = $("#P").val();
    let r = $("#r").val();
    let N = $("#N").val();
    let type = $("input[name='type']:checked").val();
    
    let arr1 = [P, r, N, type];
    accumulate_arrs.push(arr1);

    let idx = 0;
    for (let arr of accumulate_arrs) {
      idx += 1;
      P = arr[0];
      r = arr[1];
      N = arr[2];
      type = arr[3];
      let type_zh = '等额本息';
      if(type == 2) {
        type_zh = '等额本金';
      }
      $("#accumulate_info").append("<p>组合"+idx+": 本金"+P+"万元, 年利率"+r+"%, 期数"+N+"月, 方式："+type_zh+";</p>");
      $("#accumulate_info").append("<br>");
    }

  }

  function clear_accumulate() {
    $("#accumulate_info").empty();
    $("#table").empty();
    accumulate_arrs = [];
  }

  var table_arrs = [];
  function calc() {
    if (accumulate_arrs.length > 1) {
      calc_accumulate();
    } else {
      init_table();
      let P = $("#P").val()*10000;
      let r = $("#r").val()/100;
      let N = $("#N").val();
      let type = $("input[name='type']:checked").val();

      if (type == 1) {
        set_table_content(calc_1(P, r, N));
      }

      if (type == 2) {
        set_table_content(calc_2(P, r, N));
      }
      init_table_event();
    }
  }

  function calc_accumulate () {
    let res = [];
    for (let arr of accumulate_arrs) {
      P = arr[0]*10000;
      r = arr[1]/100;
      N = arr[2];
      type = arr[3];
      if (type == 1) {
        res.push(calc_1(P, r, N));
      }
      if (type == 2) {
        res.push(calc_2(P, r, N));
      }
    }

    res = adjustNestedArrays(res);

    init_table();
    set_table_content( mergeArrays(res) );
    init_table_event();
  }

  function calc_1(P, r, N) {
    let R = r / 12;
    let BX = round_2( P*(R*(1+R)**N)/((1+R)**N-1) );

    let added_X = 0;
    let added_B = 0;
    let added = 0;
    table_arrs = [];
    for(let n = 1; n <= N; n++) {
      let B = round_2( P*R*(1+R)**(n-1)/((1+R)**N-1) );
      
      let X = round_2( BX - B );

      let M = round_2( B + X );

      added_X = round_2( added_X + X );
      added_B = round_2( added_B + B );
      added = round_2( added_X + added_B );

      let arr = [n, X, B, M, added_X, added_B, added];
      table_arrs.push(arr);
    }
    return table_arrs;
  }

  function calc_2(P, r, N) {
    let R = r / 12;
    let B = round_2( P / N );
    let added_X = 0;
    let added_B = 0;
    let added = 0;
    table_arrs = [];
    for(let n = 1; n <= N; n++) {
      let X = round_2( (P - (n-1) * B)*R );

      added_X = round_2( added_X + X );
      added_B = round_2( added_B + B );
      added = round_2( added_X + added_B );

      let M = round_2( B + X );

      let arr = [n, X, B, M, added_X, added_B, added];
      table_arrs.push(arr);
    }
    return table_arrs;
  }

  function round_2 (num){
    return Math.round( num*100 ) / 100;
  }

  function set_table_content(arrs) {
    for (let arr of arrs) {
      let tr_tag = document.createElement("tr");
      for (let e of arr) {
        let td_tag = document.createElement("td");
        td_tag.innerHTML = e;
        tr_tag.append(td_tag);
      }
      $("#table").append(tr_tag);
    }
  }

  function init_table() {
    $("#table").empty();
    let tr_tag = document.createElement("tr");
    let arr = [['期', '利息', '本金', '本期总', '累计利息', '累计本金', '累计']];
    set_table_content(arr);
  }

  function init_N_select() {
    let N_select = document.getElementById("N_select");
    let option_tag = document.createElement("option");
    option_tag.value = 20;
    option_tag.innerText = '快速选择';
    N_select.append(option_tag);
    for(let i = 1; i <= 30; i += 1){
      if (i % 3 == 0 || i % 5 == 0) {
        let option_tag = document.createElement("option");
        option_tag.value = i;
        option_tag.innerText = i + '年';
        N_select.append(option_tag);
      }
    }
  }

  function init_r_select() {
    let r_select = document.getElementById("r_select");
    let option_tag = document.createElement("option");
    option_tag.value = 3.1;
    option_tag.innerText = '快速选择';
    r_select.append(option_tag);
    for (let i of [2.6, 2.75, 3.1, 3.25, 4.35, 4.75, 4.9]) {

      let option_tag = document.createElement("option");
      option_tag.value = i;
      option_tag.innerText = i + '%/年';
      r_select.append(option_tag);

    }
  }

  function init_P_select() {
    let P_select = document.getElementById("P_select");
    let option_tag = document.createElement("option");
    option_tag.value = 50;
    option_tag.innerText = '快速选择';
    P_select.append(option_tag);
    for (let i of [30, 40, 50, 55, 65, 70, 75, 80, 85, 90]) {

      let option_tag = document.createElement("option");
      option_tag.value = i;
      option_tag.innerText = i + '万';
      P_select.append(option_tag);

    }
  }

  function init_select_input(select_id, input_id, rate) {

    // 获取N_select元素和input元素
    var select = document.getElementById(select_id);
    var input = document.getElementById(input_id);

    // 添加事件监听器
    select.addEventListener("change", function() {
      // 将选中值填充到input元素中
      input.value = select.value * rate;
    });
  }

  function init_table_event() {
    // 获取表格对象
    var table = document.getElementById("table");

    // 获取所有行
    var rows = table.getElementsByTagName("tr");

    // 为每一行添加点击事件监听器
    for (var i = 0; i < rows.length; i++) {
      rows[i].addEventListener("click", function() {
        // 清除之前选中的行的样式
        for (var j = 0; j < rows.length; j++) {
          rows[j].classList.remove("selected");
        }

        // 添加选中行的样式
        this.classList.add("selected");
      });
    }
  }
  function init_scroll_button() {
    // 点击第一个按钮滚动到页面顶部
    document.getElementById("scrollToTopBtn").addEventListener("click", function() {
      window.scrollTo({
        top: 0,
        behavior: "smooth" // 添加平滑滚动动画
      });
    });

    // 点击第二个按钮滚动到页面中间
    document.getElementById("scrollToMiddleBtn").addEventListener("click", function() {
      window.scrollTo({
        top: document.documentElement.scrollHeight / 2,
        behavior: "smooth" // 添加平滑滚动动画
      });
    });

    // 点击第三个按钮滚动到页面底部
    document.getElementById("scrollToBottomBtn").addEventListener("click", function() {
      window.scrollTo({
        top: document.documentElement.scrollHeight,
        behavior: "smooth" // 添加平滑滚动动画
      });
    });
  }

  function adjustNestedArrays(arr) {
    var maxRowLength = 0;
    // 找到最大的行长
    for (var i = 0; i < arr.length; i++) {
      maxRowLength = Math.max(maxRowLength, arr[i].length);
    }
    // 调整每一行的长度
    for (var i = 0; i < arr.length; i++) {
      while (arr[i].length < maxRowLength) {
        arr[i].push([0, 0, 0, 0, 0, 0, 0]); // 在末尾添加一个宽度为7的空数组
      }
    }
    // 递归调整嵌套数组
    for (var i = 0; i < arr.length; i++) {
      for (var j = 0; j < arr[i].length; j++) {
        if (Array.isArray(arr[i][j])) { // 如果是嵌套数组，则递归调用
          arr[i][j] = adjustNestedArrays(arr[i][j]);
        }
      }
    }
    
    return arr;
  }

  function mergeArrays(array) {
    var maxLength = array[0].length;
    var width = array[0][0].length;

    // 确保子数组的长度和宽度相同
    for (var i = 1; i < array.length; i++) {
      maxLength = Math.max(maxLength, array[i].length);
      width = Math.max(width, array[i][0].length);
    }

    var mergedArray = [];

    for (var i = 0; i < maxLength; i++) {
      var innerArray = [];
      for (var j = 0; j < width; j++) {
        var sum = 0;
        var sumStr = '';
        for (var k = 0; k < array.length; k++) {
          if (i < array[k].length && j < array[k][i].length) {
            if (j == 0) {
              if (array[k][i][j] > sum) {
                sum = array[k][i][j];
              }
            } else {
              sum = round_2( sum + array[k][i][j] );
              if (sumStr == '') {
                  sumStr += array[k][i][j];
              } else {
                  sumStr += '+' + array[k][i][j];
              }
            }
          }
        }
        let regex = /\+/;
        if (regex.test(sumStr)) {
          innerArray.push(sumStr+'='+sum);
        } else {
          innerArray.push(sum);
        }
      }
      mergedArray.push(innerArray);
    }
    return mergedArray;
  }

  function init_export() {
    document.getElementById('export-btn').addEventListener('click', function() {
      exportTableToCSV('table', 'data.csv');
    });
  }
  function exportTableToCSV(tableId, filename) {
    
    // deal head_info
    let head_info = '';
    if (accumulate_arrs.length > 1) {
      head_info = $("#accumulate_info").html();
      head_info = head_info.replace(/<br>/g, "\n");
      head_info = head_info.replace(/<\/{0,1}p>/g, "");
    } else {
      let P = $("#P").val();
      let r = $("#r").val();
      let N = $("#N").val();
      let type = $("input[name='type']:checked").val();
      let type_zh = '等额本息';
      if(type == 2) {
        type_zh = '等额本金';
      }
      head_info = "P="+P+",r="+r+",N="+N+","+type_zh;
    }

    var csv = [];
    var rows = document.querySelectorAll('#' + tableId + ' tr');
    csv.push(head_info);
    // 遍历每一行
    for (var i = 0; i < rows.length; i++) {
      var row = [];
      var cols = rows[i].querySelectorAll('td, th');

      // 遍历行中的每个单元格
      for (var j = 0; j < cols.length; j++) {
        row.push(cols[j].innerText);
      }

      // 将该行添加到CSV中
      csv.push(row.join(','));
    }

    // 创建一个包含CSV内容的Blob对象
    var csvContent = csv.join('\n');
    var blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });

    // 创建一个下载链接并模拟点击该链接来下载文件
    var link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = filename;
    link.style.display = 'none';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  $(document).ready(function(){
    // 获取N_select元素和input元素
    init_select_input('N_select', 'N', 12);
    init_select_input('r_select', 'r', 1);
    init_select_input('P_select', 'P', 1);

    init_N_select();
    init_r_select();
    init_P_select();

    init_table_event();
    init_scroll_button();
    init_export();
  });
</script>



@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="zh-CN">
<html>
  <head>
  <meta charset="UTF-8">
  <meta name="author" content="ywang, wybzd019@gmail.com"/>
  <meta name="format-detection" content="telphone=no, email=no, address=no"/>
  <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge,chrome=1">
  <title><%= title %></title>
  <style>
    * {
      margin: 0px;
      padding: 0px;
    }

    a:hover, a:visited, a:link, a:active {
      color:  blue;
      text-decoration: none;
    }

    html {
      font-size : 14px;
      font-family: '方正舒体','Times New Roman', simsun, 微软雅黑;
    }
    
  </style>

  
  </head>
  <body>
  <script src="jquery-3.6.0.min.js"></script>
  <%= content %>
  </body>
</html>
