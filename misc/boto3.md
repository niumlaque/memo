# Python3 + boto3 の使用方法
諸事情でコピペしていないため、typo があるかも。
見つけたらその時になおす。
ていうか自分用のメモなので自分がわかれば良いのノリで記述する。

## セッション作成
あまり使わないかも

```py
import os
import boto3

session = boto3.Session(
    aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID", "<DEFAULT>"),
    aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY", "<DEFAULT>"),
    region_name=os.environ.get("AWS_REGION_NAME", "ap-northeast-1")
)
```

## SQS
### Client 作成
```py
from typing import Optional
import os
import boto3

def create_client(endpoint_url: Optional[str] = None):
    client = boto3.client("sqs", endpoint_url=endpoint_url)
    return client
```

### 先頭メッセージ取得
visibility_timeout: 可視性タイムアウト(秒)
この値を 0 にすると本当に値を取得するだけになる。
取得したデータを削除したい場合などは 0 を超えた値にする必要がある。

```py
from typing import Any, Dict, Optional

def peek(
    queue_url: str,
    visibility_timeout: int = 0,
) -> Optional[Dict[str, Any]:
    resp = client.receive_message(
        QueueUrl=queue_url,
        maxNumberOfMessages=1,
        VisibilityTimeout=visibility_timeout,
        WaitTimeSeconds=1,
    )
    messages = resp.get("Messages")
    if messages is not None and len(messages) > 0:
        return messages[0]

    return None
```

### メッセージ追加
```py
from typing import Any, Dict
from uuid import uuid4
import json
import boto3

def enqueue(queue_url: str, data: Dict[str, Any]):
    msg: str = json.dumps(data, ensure_awscii=False)
    if TARGET_IS_FIFO:
        return client.send_message(
            QueueUrl=queue_url,
            MessageBody=msg,
            MessageDeduplicationId=str(uuid4()),
            MessageGroupId=str(uuid4()),
        )
    else:
        return client.send_message(
            QueueUrl=queue_url,
            MessageBody=msg,
        )
```

### メッセージ削除
自分で SQS からデータを取得して消したい場合など。
SourceMapping で呼び出されている場合は不要。

```py
# データを可視性タイムアウト 60 秒で取得する
# 取得後 60 秒は削除可能
msg = peek(queue_url, visibility_timeout=60)
client.delete_message(
    QueueUrl=queue_url,
    ReceiptHandle=msg["ReceiptHandle"],
)
```