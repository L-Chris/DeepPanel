from flask import Flask, request, jsonify, send_file
import tensorflow as tf
from PIL import Image
import io
import numpy as np
from utils import normalize, map_prediction_to_mask, labeled_prediction_to_image
from metrics import iou_coef, dice_coef, border_acc, background_acc, content_acc

app = Flask(__name__)

# 加载模型
custom_objects = {
    "border_acc": border_acc,
    "background_acc": background_acc,
    "content_acc": content_acc,
    "iou_coef": iou_coef,
    "dice_coef": dice_coef
}
model = tf.keras.models.load_model("./model", custom_objects=custom_objects)

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({'error': '没有上传图片'}), 400
        
    # 读取上传的图片
    file = request.files['image']
    img = Image.open(io.BytesIO(file.read()))
    
    # 预处理图片
    img = img.convert('RGB')
    img = tf.image.resize_with_pad(tf.convert_to_tensor(np.array(img)), 
                                 target_height=224, 
                                 target_width=224)
    img = tf.cast(img, tf.float32) / 255.0
    img = tf.expand_dims(img, 0)
    
    # 预测
    prediction = model.predict(img)
    predicted_mask = map_prediction_to_mask(prediction[0])
    
    # 转换预测结果为图片
    result_img = labeled_prediction_to_image(predicted_mask)
    
    # 保存结果到内存
    img_io = io.BytesIO()
    result_img.save(img_io, 'JPEG')
    img_io.seek(0)
    
    return send_file(img_io, mimetype='image/jpeg')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) 