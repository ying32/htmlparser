# htmlparser
delphi html parser

代码是改自原wr960204的[HtmlParser](http://www.raysoftware.cn/?p=370)，因为自己的需求需要对html进行修改操作，但无奈只支持读取操作，所以在此基础上做了修改并命名为HtmlParserEx.pas与之区别。  

#### 修改记录

ying32修改于 2016年11月15日  
Email:1444386932@qq.com  

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

>
 IHtmlElementList和THtmlElementList的改变：   
  1、增加RemoveAll方法  
  2、增加Remove方法  
  3、增加Each方法    
  4、增加Text属性  

#### 修改后的新功能的一些使用法  

> IHtmlElement  

```delphi  

     EL.Attributes['class'] := 'xxxx';

     EL.TagName = 'a';

     EL.Remove; // 移除自己

     EL.RemoveChild(El2);

     El.Find('a');
```  

> IHtmlElementList  

```delphi  

  // 移除选择的元素
  LHtml.Find('a').RemoveAll;

  // 查找并遍沥
  // LHtml.Find('a').Each(
    procedure(AIndex: Integer; AEl: IHtmlElement)
    begin
      Writeln('Index=', AIndex, ',  href=', AEl.Attributes['href']);
    end);

  // 直接输出，仅选中的第一个元素
  Writeln(LHtml.Find('title').Text);

```  
