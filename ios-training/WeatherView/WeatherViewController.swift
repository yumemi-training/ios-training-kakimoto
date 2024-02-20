//
//  WeatherViewController.swift
//  ios-training
//
//  Created by 垣本 桃弥 on 2024/02/13.
//

import UIKit

/// 天気を表示する画面
final class WeatherViewController: UIViewController {
    // MARK: Properties
    
    private let myView: WeatherViewProtocol
    
    // MARK: Dependencies
    
    private let weatherInfoRepository: WeatherInfoRepositoryProtocol
    
    // MARK: Lifecycle
    
    init(view: WeatherViewProtocol = WeatherView(), weatherInfoRepository: WeatherInfoRepositoryProtocol) {
        self.myView = view
        self.weatherInfoRepository = weatherInfoRepository
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = myView
        myView.eventHandler = self
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.loadWeather()
        }
    }
}

// MARK: - WeatherViewEventHandler

extension WeatherViewController: WeatherViewEventHandler {
    func didTapCloseButton() {
        dismiss(animated: true)
    }
    
    func didTapReloadButton() {
        loadWeather()
    }
}

// MARK: - Private

private extension WeatherViewController {
    /// 天気を読み込む
    func loadWeather() {
        // 読み込み前
        myView.weatherImagePlaceholderLabel.isHidden = true
        myView.activityIndicator.startAnimating()
        myView.closeButton.isEnabled = false
        myView.reloadButton.isEnabled = false
        DispatchQueue.global().async {
            defer {
                // 読み込み完了
                DispatchQueue.main.async {
                    self.myView.activityIndicator.stopAnimating()
                    self.myView.closeButton.isEnabled = true
                    self.myView.reloadButton.isEnabled = true
                }
            }
            do {
                let weatherInfo = try self.weatherInfoRepository.fetch(at: "tokyo", date: Date())
                // 読み込み成功
                DispatchQueue.main.async {
                    self.myView.weatherImageView.image = .weatherImage(for: weatherInfo.weather)
                    self.myView.weatherImageView.tintColor = self.imageTint(for: weatherInfo.weather)
                    self.myView.lowestTemperatureLabel.text = weatherInfo.lowestTemperature.description
                    self.myView.highestTemperatureLabel.text = weatherInfo.highestTemperature.description
                }
            } catch {
                // 読み込み失敗
                DispatchQueue.main.async {
                    let alert = AlertMaker.retryOrCancelAlert(
                        title: "天気の取得に失敗しました",
                        message: "再試行しますか？",
                        didTapRetry: { [unowned self] _ in
                            self.loadWeather()
                        },
                        didTapCancel: nil
                    )
                    self.present(alert, animated: true)
                    self.myView.weatherImageView.image = nil
                    self.myView.weatherImagePlaceholderLabel.text = "取得エラー"
                    self.myView.weatherImagePlaceholderLabel.isHidden = false
                    self.myView.lowestTemperatureLabel.text = "--"
                    self.myView.highestTemperatureLabel.text = "--"
                }
            }
        }
    }
    
    /// `weatherImageView.tintColor` に指定するための色を返す
    func imageTint(for weather: Weather) -> UIColor {
        switch weather {
        case .sunny:
            UIColor.systemRed
        case .cloudy:
            UIColor.systemGray
        case .rainy:
            UIColor.tintColor
        }
    }
}

// MARK: - Preview

#Preview {
    WeatherViewController(
        weatherInfoRepository: WeatherInfoRepository(
            apiEncoder: YumemiWeatherAPIEncoder(),
            apiDecoder: YumemiWeatherAPIDecoder()
        )
    )
}
