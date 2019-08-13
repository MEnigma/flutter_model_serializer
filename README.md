# flutter_model_serializer

参照Django框架中的Serializer模块设计的model序列化方案,
#### 该实例并没有完全套用django.serializer中的全部内容,仅满足了序列化与反序列化的内容
#### 后期会对其进行扩充

## 示例
>### 1.使model继承自BaseModel

    class ExampleModel extends BaseModel{

        /// 仅有CharField修饰的字段才可以定义为主键
        final CharField uid = CharField.primary("uid");
        final IntegerField age = IntegerField("age");>

        @override
        List<AnyValueField> propertyList(){
            /// 返回字段列表
            return [uid, age];
        }
    }

>### 2.同步到数据库
`var model = ExampleModel();`

>更新数据/若没有该条数据则执行插入
>>`model.update();`


> 从本地数据库中初始化
>> `model.initFromLocal('uid',['ax111111']);`

> 反序列
>> `var model = ExampleModel.fromJson({"uid":"ax111111"});`

