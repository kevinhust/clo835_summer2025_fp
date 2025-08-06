import pytest
import sys
import os
from unittest.mock import Mock, patch, MagicMock

# Add the parent directory to the path so we can import app
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

@pytest.fixture(autouse=True)
def mock_environment():
    """Mock environment variables for testing"""
    env_vars = {
        'DBHOST': 'localhost',
        'DBUSER': 'testuser',
        'DBPWD': 'testpass',
        'DATABASE': 'testdb',
        'DBPORT': '3306',
        'APP_COLOR': 'blue',
        'GROUP_NAME': 'Test Group',
        'GROUP_SLOGAN': 'Test Slogan',
        'AWS_ACCESS_KEY_ID': 'test_key',
        'AWS_SECRET_ACCESS_KEY': 'test_secret',
        'AWS_REGION': 'us-east-1'
    }
    with patch.dict(os.environ, env_vars, clear=False):
        yield

@pytest.fixture(autouse=True)
def mock_database():
    """Mock database connection globally"""
    with patch('pymysql.connections.Connection') as mock_conn:
        mock_instance = Mock()
        mock_conn.return_value = mock_instance
        # Mock cursor
        mock_cursor = Mock()
        mock_instance.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = ('1', 'John', 'Doe', 'Python', 'Toronto')
        yield mock_instance

@pytest.fixture(autouse=True)
def mock_boto3():
    """Mock boto3 globally"""
    with patch('boto3.client') as mock_client:
        mock_instance = Mock()
        mock_client.return_value = mock_instance
        yield mock_instance

@pytest.fixture
def app_client():
    """Create a test client for the Flask application"""
    # Import app after all mocking is in place
    import app
    app.app.config['TESTING'] = True
    with app.app.test_client() as client:
        yield client

class TestAppConfiguration:
    """Test application configuration and initialization"""
    
    def test_color_codes_defined(self):
        import app
        assert 'red' in app.color_codes
        assert 'green' in app.color_codes
        assert 'blue' in app.color_codes
        assert 'lime' in app.color_codes
    
    def test_supported_colors_string(self):
        import app
        assert isinstance(app.SUPPORTED_COLORS, str)
        assert 'red' in app.SUPPORTED_COLORS
        assert 'green' in app.SUPPORTED_COLORS

class TestRoutes:
    """Test Flask application routes"""
    
    def test_home_route(self, app_client):
        """Test the home route returns 200"""
        response = app_client.get('/')
        assert response.status_code == 200
        assert b'Employee Database' in response.data or b'employee' in response.data.lower()
    
    def test_about_route(self, app_client):
        """Test the about route returns 200"""
        response = app_client.get('/about')
        assert response.status_code == 200
    
    def test_getemp_route(self, app_client):
        """Test the get employee route returns 200"""
        response = app_client.get('/getemp')
        assert response.status_code == 200

class TestEmployeeOperations:
    """Test employee-related operations"""
    
    def test_add_employee_success(self, app_client):
        """Test adding an employee successfully"""
        # Test data
        employee_data = {
            'emp_id': '1',
            'first_name': 'John',
            'last_name': 'Doe',
            'primary_skill': 'Python',
            'location': 'Toronto'
        }
        
        response = app_client.post('/addemp', data=employee_data)
        assert response.status_code == 200
        assert b'John Doe' in response.data or b'John' in response.data
    
    def test_fetch_employee_success(self, app_client):
        """Test fetching an employee successfully"""
        response = app_client.post('/fetchdata', data={'emp_id': '1'})
        assert response.status_code == 200

class TestS3Integration:
    """Test S3 integration functionality"""
    
    def test_download_background_image_s3_url(self):
        """Test downloading background image with S3 URL"""
        import app
        
        # Mock successful download
        with patch.dict(os.environ, {'BACKGROUND_IMAGE_URL': 's3://test-bucket/background.jpg'}):
            with patch('os.makedirs'):
                with patch.object(app, 's3_client') as mock_s3:
                    with patch.object(app, 'BACKGROUND_IMAGE_URL', 's3://test-bucket/background.jpg'):
                        # Ensure s3_client is truthy for the test
                        mock_s3.__bool__ = lambda self: True
                        result = app.download_background_image()
                        assert result == '/static/background.jpg'
    
    def test_download_background_image_no_client(self):
        """Test download when S3 client is not available"""
        import app
        
        with patch('app.s3_client', None):
            result = app.download_background_image()
            assert result is None
    
    def test_download_background_image_invalid_url(self):
        """Test download with invalid URL format"""
        import app
        
        with patch.dict(os.environ, {'BACKGROUND_IMAGE_URL': 'invalid-url'}):
            with patch('app.s3_client') as mock_s3:
                result = app.download_background_image()
                assert result is None

class TestErrorHandling:
    """Test error handling scenarios"""
    
    def test_fetch_employee_not_found(self, app_client):
        """Test fetching a non-existent employee"""
        response = app_client.post('/fetchdata', data={'emp_id': '999'})
        # Should still return 200 but handle the exception gracefully
        assert response.status_code == 200

class TestColorHandling:
    """Test color handling functionality"""
    
    def test_color_from_environment(self):
        """Test that color is set from environment variable"""
        import app
        # Color should be available in color_codes
        assert 'red' in app.color_codes
        assert 'blue' in app.color_codes
    
    def test_random_color_generation(self):
        """Test that a random color is generated"""
        import app
        assert app.COLOR in app.color_codes

if __name__ == '__main__':
    pytest.main([__file__])