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