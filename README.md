# htmlparser
delphi html parser

代码是改自原wr960204的[HtmlParser](http://www.raysoftware.cn/?p=370)，因为自己的需求需要对html进行修改操作，但无奈只支持读取操作，所以在此基础上做了修改并命名为HtmlParserEx.pas与之区别。  


#### 使用

```delphi
// 从文件加载示例
procedure Test;
var
  LHtml: IHtmlElement;
  LList: IHtmlElementList;
  LStrStream: TStringStream;
begin
  LStrStream := TStringStream.Create('', TEncoding.UTF8);
  try
    LStrStream.LoadFromFile('view-source_https___github.com_ying32_htmlparser.html');
    LHtml := ParserHTML(LStrStream.DataString);
    if LHtml <> nil then
    begin
      LList := LHtml.SimpleCSSSelector('a');
      for LHtml in LList do
        Writeln('url:', lhtml.Attributes['href']);
    end;
  finally
    LStrStream.Free;
  end;
end;
```


#### 修改记录
ying32修改记录：  
Email:1444386932@qq.com  

 2017年05月04日

 1、去除RegularExpressions单元的引用，不再使用TRegEx改使用RegularExpressionsCore单元中的TPerlRegEx

 2017年04月19日 

 1、增加使用XPath功能的编译指令"UseXPath"，默认不使用XPath，个人感觉没什么用  
 
 2016年11月23日  

 1、简单支持XPath，简单的吧，利用xpath转css selector，嘿  
    xpath转换的代码改自[python版本](https://github.com/santiycr/cssify/blob/master/cssify.py)
    
> IHtmlElement  

```delphi  

  LHtml.FindX('/html/head/title').Each(
    procedure(AIndex: Integer; AEl: IHtmlElement) 
    begin
      Writeln('xpath index=', AIndex, ',  a=', AEl.Text);  
    end
  );

```  
   

2016年11月15日  


>  
 IHtmlElement和THtmlElement的改变：    
  1、Attributes属性增加Set方法    
  2、TagName属性增加Set方法  
  3、增加Parent属性    
  4、增加RemoveAttr方法    
  5、增加Remove方法  
  6、增加RemoveChild方法  
  7、增加Find方法，此为SimpleCSSSelector的一个另名  
  8、_GetHtml不再直接附加FOrignal属性值，而是使用GetSelfHtml重新对修改后的元素进行赋值操作，并更新FOrignal的值  
  9、增加Text属性  
  10、修改InnerText与Text属性增加write功能
  11、增加AppedChild方法 

>
 IHtmlElementList和THtmlElementList的改变：   
  1、增加RemoveAll方法  
  2、增加Remove方法  
  3、增加Each方法    
  4、增加Text属性  

#### 修改后的新功能的一些使用法  

> IHtmlElement  

```delphi  
     // 修改属性
     EL.Attributes['class'] := 'xxxx';
     // 修改标记
     EL.TagName = 'a';
     // 移除自己
     EL.Remove; 
     // 移除子结点
     EL.RemoveChild(El2);
     // css选择器查找，简化用
     El.Find('a');
     // 附加一个新的元素
     el2 := El.AppendChild('a');
     
     
```  

> IHtmlElementList  

```delphi  

  // 移除选择的元素
  LHtml.Find('a').RemoveAll;

  // 查找并遍沥
  LHtml.Find('a').Each(
    procedure(AIndex: Integer; AEl: IHtmlElement)
    begin
      Writeln('Index=', AIndex, ',  href=', AEl.Attributes['href']);
    end);

  // 直接输出，仅选中的第一个元素
  Writeln(LHtml.Find('title').Text);

```  
