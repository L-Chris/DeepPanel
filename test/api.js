const fs = require('fs');
const FormData = require('form-data');
const axios = require('axios');
const path = require('path');

const API_URL = 'http://localhost:5000';

async function testPredictAPI(imagePath) {
    try {
        // 创建 FormData 对象
        const formData = new FormData();
        
        // 读取并添加图片文件
        const imageFile = fs.createReadStream(imagePath);
        formData.append('image', imageFile);

        console.log(`正在发送图片: ${path.basename(imagePath)}`);
        
        // 发送 POST 请求
        const response = await axios.post(`${API_URL}/predict`, formData, {
            headers: {
                ...formData.getHeaders(),
            },
            responseType: 'arraybuffer'  // 因为返回的是图片数据
        });

        // 保存返回的图片
        const outputPath = `./output/${path.basename(imagePath)}`;
        fs.writeFileSync(outputPath, response.data);
        console.log(`预测结果已保存到: ${outputPath}`);
        
    } catch (error) {
        console.error('错误:', error.message);
        if (error.response) {
            console.error('响应状态:', error.response.status);
            console.error('响应数据:', error.response.data.toString());
        }
    }
}

// 获取命令行参数中的图片路径
const imagePath = process.argv[2];

if (!imagePath) {
    console.error('请提供图片路径');
    console.error('使用方法: node test_api.js <图片路径>');
    process.exit(1);
}

// 测试单张图片
testPredictAPI(imagePath).then(() => {
    console.log('测试完成');
}); 